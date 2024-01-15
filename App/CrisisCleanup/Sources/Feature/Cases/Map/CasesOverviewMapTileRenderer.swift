import Atomics
import Combine
import CoreLocation
import LRUCache
import MapKit

class CasesMapDotsOverlay: MKTileOverlay {
    private let worksitesRepository: WorksitesRepository
    private let mapCaseDotProvider: MapCaseDotProvider
    private let filterRepository: CasesFilterRepository

    private let renderingCounter = ManagedAtomic(0)
    private let renderingCount = CurrentValueSubject<Int, Never>(0)
    var isBusy: any Publisher<Bool, Never>

    var zoomThreshold = CasesConstant.MapDotsZoomLevel

    private let cacheLock = NSLock()
    private var tileCache = TileDataCache(3000)
    private var incidentIdCache: Int64 = -1
    private var worksitesCount = 0
    private var filtersLocationCache = (CasesFilter(), false)

    private var locationCoordinates: CLLocation? = nil

    private var _emptyTile: Data?
    private var emptyTile: Data {
        if _emptyTile == nil {
            let renderer = UIGraphicsImageRenderer(size: tileSize)
            _emptyTile = renderer.pngData { _ in }
        }
        return _emptyTile!
    }

    init(
        worksitesRepository: WorksitesRepository,
        mapCaseDotProvider: MapCaseDotProvider,
        filterRepository: CasesFilterRepository
    ) {
        self.worksitesRepository = worksitesRepository
        self.mapCaseDotProvider = mapCaseDotProvider
        self.filterRepository = filterRepository

        isBusy = renderingCount
            .map { $0 > 0 }

        super.init(urlTemplate: nil)
        maximumZ = zoomThreshold
    }

    func rendersAt(_ zoom: Double) -> Bool {
        Int(zoom.rounded(.up)) < zoomThreshold + 1
    }

    func onStateChange(
        _ id: Int64,
        _ worksitesCount: Int,
        _ filtersLocation: (CasesFilter, Bool),
        _ clearCache: Bool
    ) -> Bool {
        var isChange = false
        cacheLock.withLock {
            let isIncidentChanged = id != incidentIdCache
            incidentIdCache = id

            self.worksitesCount = worksitesCount

            let isFiltersChange = filtersLocationCache.0 != filtersLocation.0 || filtersLocationCache.1 != filtersLocation.1
            filtersLocationCache = filtersLocation

            if isIncidentChanged || isFiltersChange || clearCache {
                isChange = true
                tileCache.clear()
            }
        }

        return isChange
    }

    func setLocation(_ coordinates: CLLocation?) {
        locationCoordinates = coordinates
    }

    override func loadTile(at path: MKTileOverlayPath) async throws -> Data {
        let incidentId = incidentIdCache

        if path.z >= zoomThreshold ||
            worksitesCount == 0 {
            return emptyTile
        }

        let coordinates = TileCoordinates(
            x: path.x,
            y: path.y,
            zoom: path.z
        )
        // TODO: Caching framework is poor. Fix when time avails.
//        if let tileData = tileCache.get(coordinates),
//           tileData.tileCaseCount == 0 || tileData.tile != nil {
//            return tileData.tile ?? emptyTile
//        }

        let tile = try await renderTile(coordinates)

        if incidentId != incidentIdCache {
            throw CancellationError()
        }

        return tile ?? emptyTile
    }

    private func renderTile(_ coordinates: TileCoordinates) async throws -> Data? {
        renderingCounter.wrappingIncrement(ordering: .sequentiallyConsistent)
        renderingCount.value = renderingCounter.load(ordering: .sequentiallyConsistent)
        do {
            defer {
                renderingCounter.wrappingDecrement(ordering: .sequentiallyConsistent)
                renderingCount.value = renderingCounter.load(ordering: .sequentiallyConsistent)
            }

            return try await renderTileInternal(coordinates)
        }
    }

    private func renderTileInternal(_ coordinates: TileCoordinates) async throws -> Data? {
        let incidentId = incidentIdCache

        let (_, imageData) = try await renderTile(incidentId, worksitesCount, coordinates)

        let tile = imageData == nil ? emptyTile : imageData

        // TODO: Caching framework is poor. Fix when time avails.
//        cacheLock.withLock {
//            if incidentId == incidentIdCache {
//                let tileData = MapTileCases(
//                    tileCaseCount: boundedWorksitesCount,
//                    incidentCaseCount: worksitesCount,
//                    tile: tile
//                )
//                tileCache.add(coordinates, tileData)
//            }
//        }

        return tile
    }

    private func renderTile(
        _ incidentId: Int64,
        _ worksitesCount: Int,
        _ coordinates: TileCoordinates
    ) async throws -> (Int, Data?) {
        let limit = 5000
        var offset = 0
        // TODO: Why does the offset require scaling by 2 (as opposed to 1)
        let centerDotOffset = -mapCaseDotProvider.iconOffset.0 * 2

        let sw = coordinates.querySouthwest
        let ne = coordinates.queryNortheast

        var allWorksites = [WorksiteMapMark]()

        for _ in stride(from: 0, to: worksitesCount, by: limit) {
            let worksites = try await worksitesRepository.getWorksitesMapVisual(
                incidentId: incidentId,
                latitudeSouth: sw.latitude,
                latitudeNorth: ne.latitude,
                longitudeWest: sw.longitude,
                longitudeEast: ne.longitude,
                limit: limit,
                offset: offset,
                coordinates: locationCoordinates,
                // TODO: Replace with observable pattern if causes bugs
                casesFilters: filterRepository.casesFilters
            )

            // Incident has changed this tile is invalid
            if (incidentId != incidentIdCache) {
                throw CancellationError()
            }

            allWorksites.append(contentsOf: worksites)

            // There are no more worksites in this tile
            if worksites.count < limit {
                break
            }

            offset += limit
        }

        let boundedWorksitesCount = allWorksites.count

        var tileImage: UIImage?
        if allWorksites.isNotEmpty {
            let renderer = UIGraphicsImageRenderer(size: tileSize)
            let data = renderer.pngData { context in
                allWorksites.forEach {
                    if let dotImage = mapCaseDotProvider.getIcon(
                        $0.statusClaim,
                        $0.workType,
                        $0.workTypeCount > 1,
                        isFilteredOut: $0.isFilteredOut,
                        isDuplicate: $0.isDuplicate
                    ),
                       let xyNorm = coordinates.fromLatLng($0.latitude, $0.longitude) {
                        let (xNorm, yNorm) = xyNorm
                        let left = xNorm * tileSize.width + centerDotOffset
                        let top = yNorm * tileSize.height + centerDotOffset
                        dotImage.draw(at: CGPoint(x: left, y: top))
                    }
                }
            }
            tileImage = UIImage(data: data)
        }

        return (boundedWorksitesCount, tileImage?.pngData())
    }
}

class TileCoordinateOverlay: MKTileOverlay {
    var renderText: Bool = false

    /// Use a 2 x 2 grid of colors so the same color is never adjacent to itself, to make the tile boundaries obvious.
    private let tileColors = [ [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.05), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.05)],
                               [#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.05), #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.05)] ]

    override func loadTile(at path: MKTileOverlayPath) async throws -> Data {
        /**
         Usually, you provide prerendered tiles and either load them from disk or the network rather than creating them on-demand, as they are here.
         Because the purpose of this tile overlay is to visualize the tile paths and zoom levels for all tiles worldwide, providing a prerendererd
         tile set for the entire world is infeasible.
         */
        let renderer = UIGraphicsImageRenderer(size: tileSize)
        let data = renderer.pngData { context in

            let color = tileColors[path.x % 2][path.y % 2]
            color.setFill()
            context.fill(CGRect(origin: .zero, size: tileSize))

            if renderText {
                let text = """
                        Tile Path (\(path.x), \(path.y))
                        Zoom: \(path.z)
                       """

                let rect = CGRect(origin: CGPoint(x: 10, y: 10), size: tileSize)
                let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)]
                text.draw(in: rect, withAttributes: attributes)
            }
        }

        return data
    }
}

private struct MapTileCases {
    let tileCaseCount: Int
    let incidentCaseCount: Int
    let tile: Data?
}

private class TileDataCache {
    private let cache: LRUCache<TileCoordinates, MapTileCases>

    init (_ sizeKb: Int) {
        cache = LRUCache(totalCostLimit: sizeKb)
    }

    func clear() {
        cache.removeAllValues()
    }

    func add(
        _ coordinates: TileCoordinates,
        _ tile: MapTileCases
    ) {
        let cost = (tile.tile?.count ?? 0) / 1000
        cache.setValue(tile, forKey: coordinates, cost: cost)
    }

    func get(_ coordinates: TileCoordinates) -> MapTileCases? {
        cache.value(forKey: coordinates)
    }
}
