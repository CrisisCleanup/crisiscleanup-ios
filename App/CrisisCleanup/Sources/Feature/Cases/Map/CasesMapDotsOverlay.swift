import Atomics
import Combine
import CoreLocation
import LRUCache
import MapKit

class CasesMapDotsOverlay: MKTileOverlay {
    private let worksitesRepository: WorksitesRepository
    private let mapCaseDotProvider: MapCaseDotProvider
    private let filterRepository: CasesFilterRepository
    private let logger: AppLogger

    private let renderingCounter = ManagedAtomic(0)
    private let renderingCount = CurrentValueSubject<Int, Never>(0)
    var isBusy: any Publisher<Bool, Never>

    var isGeneratingTiles: Bool {
        renderingCounter.load(ordering: .relaxed) > 0
    }

    private let zoomThreshold = CasesConstant.MAP_DOTS_ZOOM_LEVEL

    private let cacheLock = NSRecursiveLock()
    private var tileCache = TileDataCache(3000)
    // TODO: Atomic
    private var incidentChangeIdentifier = IncidentChangeIdentifier(EmptyIncident.id, 0)
    private var filtersLocationCache = (CasesFilter(), false, 0.0)

    private let loadTileZoom = AtomicInt(-1)

    var tilesIncident: Int64 {
        incidentChangeIdentifier.id
    }

    private var locationCoordinates: CLLocation? = nil

    private lazy var emptyTile: Data = {
        let renderer = UIGraphicsImageRenderer(size: tileSize)
        return renderer.pngData { _ in }
    }()

    init(
        worksitesRepository: WorksitesRepository,
        mapCaseDotProvider: MapCaseDotProvider,
        filterRepository: CasesFilterRepository,
        logger: AppLogger,
    ) {
        self.worksitesRepository = worksitesRepository
        self.mapCaseDotProvider = mapCaseDotProvider
        self.filterRepository = filterRepository
        self.logger = logger

        isBusy = renderingCount
            .map { $0 > 0 }

        super.init(urlTemplate: nil)
        maximumZ = zoomThreshold
    }

    func setIncident(
        _ id: Int64,
        _ worksitesCount: Int,
        clearCache: Bool
    ) {
        cacheLock.withLock {
            let isIncidentChanged = id != incidentChangeIdentifier.id
            if isIncidentChanged || clearCache {
                tileCache.clear()
            }
            incidentChangeIdentifier = IncidentChangeIdentifier(id, worksitesCount)
        }
    }

    func setLocation(_ coordinates: CLLocation?) {
        locationCoordinates = coordinates
    }

    override func loadTile(at path: MKTileOverlayPath) async throws -> Data {
        let changeIdentifier = incidentChangeIdentifier
        let incidentId = changeIdentifier.id
        let worksitesCount = changeIdentifier.count

        let zoom = path.z
        if zoom >= zoomThreshold ||
            worksitesCount == 0 {
            return emptyTile
        }

        let coordinates = TileCoordinates(
            x: path.x,
            y: path.y,
            zoom: zoom,
        )

        loadTileZoom.set(zoom)

        if let cached = (cacheLock.withLock {
            return if let tileData = tileCache.get(coordinates),
                      tileData.incidentId == incidentId,
                      tileData.incidentCaseCount == worksitesCount,
                      tileData.tileCaseCount == 0 || tileData.tile != nil {
                tileData.tile ?? emptyTile
            } else {
                nil
            }
        }) {
            return cached
        }

        do {
            let tile = try await renderCountTile(
                coordinates,
                changeIdentifier,
                zoom,
            )

            if changeIdentifier != incidentChangeIdentifier
            {
                throw CancellationError()
            }
            try Task.checkCancellation()

            return tile ?? emptyTile
        } catch {
            return emptyTile
        }
    }

    private func renderCountTile(
        _ coordinates: TileCoordinates,
        _ changeIdentifier: IncidentChangeIdentifier,
        _ zoom: Int,
    ) async throws -> Data? {
        renderingCounter.wrappingIncrement(ordering: .sequentiallyConsistent)
        renderingCount.value = renderingCounter.load(ordering: .sequentiallyConsistent)
        do {
            defer {
                renderingCounter.wrappingDecrement(ordering: .sequentiallyConsistent)
                renderingCount.value = renderingCounter.load(ordering: .sequentiallyConsistent)
            }

            return try await renderCacheTile(
                coordinates,
                changeIdentifier,
                zoom,
            )
        }
    }

    private func renderCacheTile(
        _ coordinates: TileCoordinates,
        _ changeIdentifier: IncidentChangeIdentifier,
        _ zoom: Int,
    ) async throws -> Data? {
        let (boundedWorksitesCount, imageData) = try await renderTile(coordinates, changeIdentifier, zoom)

        let tile = imageData == nil ? emptyTile : imageData
        let tileData = MapTileCases(
            incidentId: changeIdentifier.id,
            tileCaseCount: boundedWorksitesCount,
            incidentCaseCount: changeIdentifier.count,
            tile: tile,
        )

        try Task.checkCancellation()
        cacheLock.withLock {
            tileCache.add(coordinates, tileData)
        }

        return tile
    }

    private func renderTile(
        _ coordinates: TileCoordinates,
        _ changeIdentifier: IncidentChangeIdentifier,
        _ zoom: Int,
    ) async throws -> (Int, Data?) {
        let limit = 4000
        var offset = 0
        // TODO: Why does the offset require scaling by 2 (as opposed to 1)
        let centerDotOffset = -mapCaseDotProvider.iconOffset.0 * 2

        let sw = coordinates.querySouthwest
        let ne = coordinates.queryNortheast

        var allWorksites = [WorksiteMapMark]()

        func checkCancellation() throws {
            if changeIdentifier != incidentChangeIdentifier ||
                zoom != loadTileZoom.value {
                throw CancellationError()
            }
            try Task.checkCancellation()
        }

        for _ in stride(from: 0, to: incidentChangeIdentifier.count, by: limit) {
            let worksites = try await worksitesRepository.getWorksitesMapVisual(
                incidentId: incidentChangeIdentifier.id,
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

            try checkCancellation()

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
                var w = 0
                for worksite in allWorksites {
                    w += 1

                    if let dotImage = mapCaseDotProvider.getIcon(
                        worksite.statusClaim,
                        worksite.workType,
                        worksite.workTypeCount > 1,
                        isFilteredOut: worksite.isFilteredOut,
                        isDuplicate: worksite.isDuplicate,
                        isVisited: false,
                        hasPhotos: worksite.hasPhotos,
                    ),
                       let xyNorm = coordinates.fromLatLng(worksite.latitude, worksite.longitude) {
                        let (xNorm, yNorm) = xyNorm
                        let left = xNorm * tileSize.width + centerDotOffset
                        let top = yNorm * tileSize.height + centerDotOffset
                        dotImage.draw(at: CGPoint(x: left, y: top))
                    }

                    if w % 2000 == 0,
                       Task.isCancelled ||
                        changeIdentifier != incidentChangeIdentifier ||
                        zoom != loadTileZoom.value {
                        break
                    }
                }
            }
            tileImage = UIImage(data: data)
        }

        try checkCancellation()

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
    let incidentId: Int64
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

private struct IncidentChangeIdentifier: Equatable {
    typealias AtomicRepresentation = IncidentChangeIdentifier

    let id: Int64
    let count: Int
    let timestamp: Double

    init(
        _ id: Int64,
        _ count: Int,
        timestamp: Double = Date.now.timeIntervalSince1970
    ) {
        self.id = id
        self.count = count
        self.timestamp = timestamp
    }
}
