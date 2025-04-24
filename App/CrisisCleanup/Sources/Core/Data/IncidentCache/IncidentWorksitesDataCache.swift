import Foundation

protocol WorksitesNetworkDataCache {
    func loadWorksitesShort(
        incidentId: Int64,
        pageIndex: Int,
        expectedCount: Int
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
    )

    func loadWorksitesSecondaryData(
        incidentId: Int64,
        pageIndex: Int,
        expectedCount: Int
    ) throws -> IncidentWorksitesSecondaryDataPageRequest?

    func saveWorksitesSecondaryData(
        incidentId: Int64,
        pageCount: Int,
        pageIndex: Int,
        expectedCount: Int,
        updatedAfter: Date?
    ) async throws

    func deleteWorksitesSecondaryData(
        _ incidentId: Int64,
        _ pageIndex: Int
    )
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
        logger = loggerFactory.getLogger("wsync-cache")

        jsonDecoder = JsonDecoderFactory().decoder()
        jsonEncoder = JsonEncoderFactory().encoder()
    }

    private func loadCacheData<T: IncidentCacheDataPageRequest>(
        cacheFileName: String,
        incidentId: Int64,
        pageIndex: Int,
        expectedCount: Int
    ) throws -> T? {
        let fileUrl = try cacheFileUrl(cacheFileName)
        let filePath = fileUrl.path
        if FileManager.default.fileExists(atPath: filePath) {
            if let contents = try? Data(contentsOf: fileUrl) {
                let cachedData = try jsonDecoder.decode(T.self, from: contents)
                if cachedData.incidentId == incidentId &&
                    cachedData.page == pageIndex &&
                    cachedData.totalCount == expectedCount &&
                    // TODO Use configurable duration
                    cachedData.requestTime.addingTimeInterval(4.days) > Date.now
                {
                    return cachedData
                }
            }
        }
        return nil
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
        incidentId: Int64,
        pageIndex: Int,
        expectedCount: Int
    ) throws -> IncidentWorksitesPageRequest? {
        try loadCacheData(
            cacheFileName: shortWorksitesFileName(incidentId, pageIndex),
            incidentId: incidentId,
            pageIndex: pageIndex,
            expectedCount: expectedCount
        )
    }

    func saveWorksitesShort(
        incidentId: Int64,
        pageCount: Int,
        pageIndex: Int,
        expectedCount: Int,
        updatedAfter: Date?
    ) async throws {
        do {
            if let _ = try loadWorksitesShort(
                incidentId: incidentId,
                pageIndex: pageIndex,
                expectedCount: expectedCount
            ) {
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

        let cacheFileName = shortWorksitesFileName(incidentId, pageIndex)
        let json = try jsonEncoder.encode(dataCache)
        let fileUrl = try cacheFileUrl(cacheFileName)
        try json.write(to: fileUrl, options: .atomic)
    }

    func deleteWorksitesShort(
        _ incidentId: Int64,
        _ pageIndex: Int
    ) {
        let cacheFileName = shortWorksitesFileName(incidentId, pageIndex)
        deleteCacheFile(cacheFileName)
    }

    private func deleteCacheFile(_ cacheFileName: String) {
        do {
            let fileUrl = try cacheFileUrl(cacheFileName)
            try FileManager.default.removeItem(at: fileUrl)
        } catch {
            logger.logDebug("Error deleting cache file \(cacheFileName). \(error)")
        }
    }

    private func secondaryDataFileName(_ incidentId: Int64, _ page: Int) -> String {
        "incident-\(incidentId)-worksites-secondary-data-\(page).json"
    }

    func loadWorksitesSecondaryData(
        incidentId: Int64,
        pageIndex: Int,
        expectedCount: Int
    ) throws -> IncidentWorksitesSecondaryDataPageRequest? {
        try loadCacheData(
            cacheFileName: secondaryDataFileName(incidentId, pageIndex),
            incidentId: incidentId,
            pageIndex: pageIndex,
            expectedCount: expectedCount
        )
    }

    func saveWorksitesSecondaryData(
        incidentId: Int64,
        pageCount: Int,
        pageIndex: Int,
        expectedCount: Int,
        updatedAfter: Date?
    ) async throws {
        do {
            if let _ = try loadWorksitesSecondaryData(
                incidentId: incidentId,
                pageIndex: pageIndex,
                expectedCount: expectedCount
            ) {
                return
            }
        } catch {
            logger.logDebug("Error reading cache file \(error)")
        }

        let requestTime = Date.now
        let secondaryData = try await networkDataSource.getWorksitesFlagsFormDataPage(
            incidentId: incidentId,
            pageCount: pageCount,
            pageOffset: pageIndex + 1,
            updatedAtAfter: updatedAfter
        )

        let dataCache = IncidentWorksitesSecondaryDataPageRequest(
            incidentId: incidentId,
            requestTime: requestTime,
            page: pageIndex,
            startCount: pageIndex * pageCount,
            totalCount: expectedCount,
            secondaryData: secondaryData
        )

        let cacheFileName = secondaryDataFileName(incidentId, pageIndex)
        let json = try jsonEncoder.encode(dataCache)
        let fileUrl = try cacheFileUrl(cacheFileName)
        try json.write(to: fileUrl, options: .atomic)
    }

    func deleteWorksitesSecondaryData(_ incidentId: Int64, _ pageIndex: Int) {
        let cacheFileName = secondaryDataFileName(incidentId, pageIndex)
        deleteCacheFile(cacheFileName)
    }
}
