import Foundation

protocol WorksitesNetworkDataCache {
    func loadWorksitesShort(
        _ incidentId: Int64,
        _ pageIndex: Int,
        _ expectedCount: Int
    ) throws -> IncidentWorksitesPageRequest?

    func saveWorksitesShort(
        incidentId: Int64,
        pageCount: Int,
        pageIndex: Int,
        expectedCount: Int,
        updatedAfter: Date?
    ) async throws

    func deleteWorksitesShort(
        _ incidentId: Int64,
        _ pageIndex: Int
    ) async
}

class WorksitesNetworkDataFileCache: WorksitesNetworkDataCache {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let logger: AppLogger

    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    private var cacheDir: URL? = nil

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        logger = loggerFactory.getLogger("worksites-cache")

        jsonDecoder = JsonDecoderFactory().decoder()
        jsonEncoder = JSONEncoder()
    }

    private func shortWorksitesFileName(_ incidentId: Int64, _ page: Int) -> String
    {
        "incident-\(incidentId)-worksites-short-\(page).json"
    }

    private func cacheFileUrl(_ fileName: String) throws -> URL {
        if cacheDir == nil {
            cacheDir = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
        return cacheDir!.appendingPathComponent(fileName)
    }

    func loadWorksitesShort(
        _ incidentId: Int64,
        _ pageIndex: Int,
        _ expectedCount: Int
    ) throws -> IncidentWorksitesPageRequest? {
        let cacheFileName = shortWorksitesFileName(incidentId, pageIndex)
        let fileUrl = try cacheFileUrl(cacheFileName)
        let filePath = fileUrl.path
        if FileManager.default.fileExists(atPath: filePath) {
            if let contents = try? Data(contentsOf: fileUrl) {
                let cachedData = try jsonDecoder.decode(IncidentWorksitesPageRequest.self, from: contents)
                if (cachedData.incidentId == incidentId &&
                    cachedData.page == pageIndex &&
                    cachedData.totalCount == expectedCount &&
                    // TODO Use configurable duration
                    cachedData.requestTime.addingTimeInterval(4.days) > Date.now
                ) {
                    return cachedData
                }
            }
        }
        return nil
    }

    func saveWorksitesShort(
        incidentId: Int64,
        pageCount: Int,
        pageIndex: Int,
        expectedCount: Int,
        updatedAfter: Date?
    ) async throws {
        let cacheFileName = shortWorksitesFileName(incidentId, pageIndex)

        do {
            if let _ = try loadWorksitesShort(incidentId, pageIndex, expectedCount) {
                return
            }
        } catch {
            logger.logDebug("Error reading cache file \(error)")
        }

        let requestTime = Date.now
        let worksites = try await networkDataSource.getWorksitesPage(
            incidentId: incidentId,
            pageCount: pageCount,
            pageOffset: pageIndex + 1,
            latitude: nil,
            longitude: nil,
            updatedAtAfter: updatedAfter
        )

        let dataCache = IncidentWorksitesPageRequest(
            incidentId: incidentId,
            requestTime: requestTime,
            page: pageIndex,
            startCount: pageIndex * pageCount,
            totalCount: expectedCount,
            worksites: worksites
        )

        let json = try jsonEncoder.encode(dataCache)
        let fileUrl = try cacheFileUrl(cacheFileName)
        try json.write(to: fileUrl, options: .atomic)
    }

    func deleteWorksitesShort(
        _ incidentId: Int64,
        _ pageIndex: Int
    ) async {
        let cacheFileName = shortWorksitesFileName(incidentId, pageIndex)
        do {
            let fileUrl = try cacheFileUrl(cacheFileName)
            try FileManager.default.removeItem(at: fileUrl)
        } catch {
            logger.logDebug("Error deleting cache file \(cacheFileName). \(error)")
        }
    }
}
