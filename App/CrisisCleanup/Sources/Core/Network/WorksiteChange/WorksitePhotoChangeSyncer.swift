class WorksitePhotoChangeSyncer {
    private let writeApiClient: CrisisCleanupWriteApi

    init(
        writeApiClient: CrisisCleanupWriteApi
    ) {
        self.writeApiClient = writeApiClient
    }

    func deletePhotoFiles(
        _ networkWorksiteId: Int64,
        _ deleteFileIds: [Int64]
    ) async throws {
        for fileId in deleteFileIds.filter({ $0 > 0 }) {
            try await writeApiClient.deleteFile(networkWorksiteId, fileId)
        }
    }
}
