import Foundation

protocol IncidentOrganizationsDataCache {
    func loadOrganizations(
        _ incidentId: Int64,
        _ dataIndex: Int,
        _ expectedCount: Int
    ) throws -> IncidentOrganizationsPageRequest?

    func saveOrganizations(
        incidentId: Int64,
        dataIndex: Int,
        expectedCount: Int,
        organizations: [NetworkIncidentOrganization]
    ) async throws

    func deleteOrganizations(
        _ incidentId: Int64,
        _ dataIndex: Int
    ) async
}

class IncidentOrganizationsDataFileCache: IncidentOrganizationsDataCache {
    private let logger: AppLogger

    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    private var cacheDir: URL? = nil

    init(
        loggerFactory: AppLoggerFactory
    ) {
        logger = loggerFactory.getLogger("org-sync-cache")

        jsonDecoder = JsonDecoderFactory().decoder()
        jsonEncoder = JsonEncoderFactory().encoder()
    }

    private func cacheFileName(_ incidentId: Int64, _ offset: Int) -> String
    {
        "incident-\(incidentId)-organizations-\(offset).json"
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

    func loadOrganizations(
        _ incidentId: Int64,
        _ dataIndex: Int,
        _ expectedCount: Int
    ) throws -> IncidentOrganizationsPageRequest? {
        let cacheFileName = cacheFileName(incidentId, dataIndex)
        let fileUrl = try cacheFileUrl(cacheFileName)
        let filePath = fileUrl.path

        if FileManager.default.fileExists(atPath: filePath) {
            if let contents = try? Data(contentsOf: fileUrl) {
                let cachedData = try jsonDecoder.decode(IncidentOrganizationsPageRequest.self, from: contents)
                if cachedData.incidentId == incidentId &&
                    cachedData.offset == dataIndex &&
                    cachedData.totalCount == expectedCount
                {
                    return cachedData
                }
            }
        }
        return nil
    }

    func saveOrganizations(
        incidentId: Int64,
        dataIndex: Int,
        expectedCount: Int,
        organizations: [NetworkIncidentOrganization]
    ) async throws {
        let cacheFileName = cacheFileName(incidentId, dataIndex)

        let dataCache = IncidentOrganizationsPageRequest(
            incidentId: incidentId,
            offset: dataIndex,
            totalCount: expectedCount,
            organizations: organizations
        )

        let json = try jsonEncoder.encode(dataCache)
        let fileUrl = try cacheFileUrl(cacheFileName)
        try json.write(to: fileUrl, options: .atomic)
    }

    func deleteOrganizations(
        _ incidentId: Int64,
        _ dataIndex: Int
    ) async {
        let cacheFileName = cacheFileName(incidentId, dataIndex)
        do {
            let fileUrl = try cacheFileUrl(cacheFileName)
            try FileManager.default.removeItem(at: fileUrl)
        } catch {
            logger.logDebug("Error deleting cache file \(cacheFileName). \(error)")
        }
    }
}
