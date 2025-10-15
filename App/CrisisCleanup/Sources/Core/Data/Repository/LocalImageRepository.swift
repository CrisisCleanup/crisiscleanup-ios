import Atomics
import Combine
import PhotosUI
import SwiftUI

public protocol LocalImageRepository {
    var syncingWorksiteId: any Publisher<Int64, Never> { get }
    var syncingWorksiteImage: any Publisher<Int64, Never> { get }

    func streamNetworkImageUrl(_ id: Int64) -> AnyPublisher<String?, Never>
    func streamLocalImageUri(_ id: Int64) -> AnyPublisher<String?, Never>

    func getImageRotation(_ id: Int64, _ isNetworkImage: Bool) -> Int

    func setImageRotation(
        _ id: Int64,
        _ isNetworkImage: Bool,
        _ rotationDegrees: Int
    )

    func cachePicked(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ tag: String,
        _ picked: [PhotosPickerItem]
    ) async throws

    func cacheImage(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ tag: String,
        _ image: UIImage
    ) async throws

    func getLocalImage(
        _ imageFileName: String
    ) -> UIImage?

    func save(_ image: WorksiteLocalImage) throws

    func deleteLocalImage(_ id: Int64) throws

    func syncWorksiteMedia(_ worksiteId: Int64) async throws -> UploadMediaResult
}

class CrisisCleanupLocalImageRepository: LocalImageRepository {
    private let worksiteDao: WorksiteDao
    private let networkFileDao: NetworkFileDao
    private let localImageDao: LocalImageDao
    private let writeApi: CrisisCleanupWriteApi
    private let localFileCache: LocalFileCache
    private let worksiteInteractor: WorksiteInteractor
    private var syncLogger: SyncLogger
    private let appLogger: AppLogger

    private let fileUploadGuard = ManagedAtomic(false)

    private let syncingWorksiteIdSubject = CurrentValueSubject<Int64, Never>(EmptyWorksite.id)
    let syncingWorksiteId: any Publisher<Int64, Never>

    private let syncingWorksiteImageSubject = CurrentValueSubject<Int64, Never>(0)
    let syncingWorksiteImage: any Publisher<Int64, Never>

    init(
        worksiteDao: WorksiteDao,
        networkFileDao: NetworkFileDao,
        localImageDao: LocalImageDao,
        writeApi: CrisisCleanupWriteApi,
        localFileCache: LocalFileCache,
        worksiteInteractor: WorksiteInteractor,
        syncLogger: SyncLogger,
        loggerFactory: AppLoggerFactory
    ) {
        self.worksiteDao = worksiteDao
        self.networkFileDao = networkFileDao
        self.localImageDao = localImageDao
        self.writeApi = writeApi
        self.localFileCache = localFileCache
        self.worksiteInteractor = worksiteInteractor
        self.syncLogger = syncLogger
        appLogger = loggerFactory.getLogger("image-repository")

        syncingWorksiteId = syncingWorksiteIdSubject
        syncingWorksiteImage = syncingWorksiteImageSubject
    }

    func streamNetworkImageUrl(_ id: Int64) -> AnyPublisher<String?, Never> {
        networkFileDao.streamNetworkImageUrl(id)
    }

    func streamLocalImageUri(_ id: Int64) -> AnyPublisher<String?, Never> {
        localImageDao.streamLocalImageUrl(id)
    }

    func getImageRotation(_ id: Int64, _ isNetworkImage: Bool) -> Int {
        isNetworkImage
        ? localImageDao.getNetworkFileLocalImage(id)?.rotateDegrees ?? 0
        : localImageDao.getLocalImage(id)?.rotateDegrees ?? 0
    }

    func setImageRotation(
        _ id: Int64,
        _ isNetworkImage: Bool,
        _ rotationDegrees: Int
    ) {
        if isNetworkImage {
            localImageDao.setNetworkImageRotation(id, rotationDegrees)
        } else {
            localImageDao.setLocalImageRotation(id, rotationDegrees)
        }
    }

    private func upsertCachedImages(
        _ worksiteId: Int64,
        _ tag: String,
        _ cached: [String: String]
    ) throws {
        for (imageName, imagePath) in cached {
            try localImageDao.upsertLocalImage(WorksiteLocalImageRecord(
                id: nil,
                worksiteId: worksiteId,
                localDocumentId: imageName,
                uri: imagePath,
                tag: tag,
                rotateDegrees: 0
            ))
        }
    }

    func cachePicked(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ tag: String,
        _ picked: [PhotosPickerItem]
    ) async throws {
        let cached = try await localFileCache.cachePicked(incidentId, worksiteId, picked)
        try upsertCachedImages(worksiteId, tag, cached)
        worksiteInteractor.onCaseChanged(incidentId, worksiteId)
    }

    func cacheImage(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ tag: String,
        _ image: UIImage
    ) async throws {
        let cached = try await localFileCache.cacheImage(incidentId, worksiteId, image)
        try upsertCachedImages(worksiteId, tag, cached)
        worksiteInteractor.onCaseChanged(incidentId, worksiteId)
    }

    func getLocalImage(
        _ imageFileName: String
    ) -> UIImage? {
        localFileCache.getImage(imageFileName)
    }

    func save(_ image: WorksiteLocalImage) throws {
        try localImageDao.upsertLocalImage(image.asRecord())
    }

    func deleteLocalImage(_ id: Int64) throws {
        try localImageDao.deleteLocalImage(id)
    }

    func syncWorksiteMedia(_ worksiteId: Int64) async throws -> UploadMediaResult {
        let imagesPendingUpload = localImageDao.getWorksiteLocalImages(worksiteId)
        if imagesPendingUpload.isEmpty {
            return UploadMediaResult(worksiteId)
        }

        let networkWorksiteId = worksiteDao.getWorksiteNetworkId(worksiteId)
        if networkWorksiteId <= 0 {
            return UploadMediaResult(worksiteId)
        }

        syncLogger.type = "worksite-\(worksiteId)-media"

        syncLogger.log("Syncing \(imagesPendingUpload.count) images")

        var syncedImageIds = Set<Int64>()

        if fileUploadGuard.compareExchange(
            expected: false,
            desired: true,
            ordering: .sequentiallyConsistent,
        ).exchanged {
            syncingWorksiteIdSubject.value = worksiteId
            do {
                defer {
                    _ = fileUploadGuard.exchange(false, ordering: .sequentiallyConsistent)
                    syncingWorksiteIdSubject.value = EmptyWorksite.id
                    syncingWorksiteImageSubject.value = 0

                    syncLogger.flush()
                }

                for localImage in imagesPendingUpload {
                    try Task.checkCancellation()
                    _ = try await UIApplication.shared.checkTimeout(15)

                    let isSynced = try await syncLocalImage(
                        worksiteId,
                        networkWorksiteId,
                        localImage
                    )

                    if isSynced {
                        syncedImageIds.insert(localImage.id)

                        syncLogger.log("Synced \(syncedImageIds.count)/\(imagesPendingUpload.count)")
                    }
                }
            }
        } else {
            syncLogger.flush()
        }

        let unsyncedIds = imagesPendingUpload.map { $0.id }
            .filter { !syncedImageIds.contains($0) }
        return UploadMediaResult(
            worksiteId,
            syncedImageIds: syncedImageIds,
            unsyncedImageIds: Set(unsyncedIds),
        )
    }

    private func getFileNameType(_ uri: URL) -> (String, String) {
        let displayName = uri.path.lastPath
        let mimeType = "image/jpeg"
        return (displayName, mimeType)
    }

    private func copyImageToData(_ uri: URL, _ fileName: String) -> Data? {
        if let image = localFileCache.getImage(fileName),
           let imageData = image.jpegData(compressionQuality: 1.0) {
            return imageData
        }

        return nil
    }

    private func uploadWorksiteFile(
        networkWorksiteId: Int64,
        fileName: String,
        file: Data,
        mimeType: String,
        imageTag: String
    ) async throws -> NetworkFile {
        let fileUpload = try await writeApi.startFileUpload(fileName, mimeType)
        let up = fileUpload.uploadProperties
        try await writeApi.uploadFile(
            up.url,
            up.fields,
            file,
            fileName,
            mimeType
        )
        return try await writeApi.addFileToWorksite(networkWorksiteId, fileUpload.id, imageTag)
    }

    private func syncLocalImage(
        _ worksiteId: Int64,
        _ networkWorksiteId: Int64,
        _ localImage: PopulatedLocalImageDescription
    ) async throws -> Bool {
        var deleteLogMessage = ""
        var isSynced = false

        if let uri = URL(string: localImage.uri) {
            do {
                let (fileName, mimeType) = getFileNameType(uri)
                if fileName.isBlank || mimeType.isBlank {
                    deleteLogMessage = "File not found from \(localImage.uri)"
                } else {
                    syncingWorksiteImageSubject.value = localImage.id

                    if let imageData = copyImageToData(uri, fileName) {
                        let networkFile = try await uploadWorksiteFile(
                            networkWorksiteId: networkWorksiteId,
                            fileName: fileName,
                            file: imageData,
                            mimeType: mimeType,
                            imageTag: localImage.tag
                        )
                        try localImageDao.saveUploadedFile(
                            worksiteId,
                            localImage,
                            networkFile.asRecord()
                        )
                        isSynced = true

                        syncLogger.log("Synced \(localImage.id) (\(networkFile.id) file \(networkFile.file!))")

                        localFileCache.deleteFile(fileName)
                    } else {
                        syncLogger.log("Unable to copy image.", details: localImage.uri)

                        try localImageDao.deleteLocalImage(localImage.id)
                        deleteLogMessage = "Missing image in cache"
                    }
                }
            } catch {
                appLogger.logError(error)

                var errorMessage = error.localizedDescription
                if let e = error as? GenericError {
                    errorMessage = e.message
                }
                syncLogger.log("Sync error", details: errorMessage)
            }
        } else {
            deleteLogMessage = "Invalid URI \(localImage.uri)"
        }

        if deleteLogMessage.isNotBlank {
            syncLogger.log(
                "Deleting image \(localImage.id)",
                details: deleteLogMessage
            )
            try localImageDao.deleteLocalImage(localImage.id)
        }

        return isSynced
    }
}

public struct UploadMediaResult {
    let worksiteId: Int64
    let syncedImageIds: Set<Int64>
    let unsyncedImageIds: Set<Int64>

    init(
        _ worksiteId: Int64,
        syncedImageIds: Set<Int64> = [],
        unsyncedImageIds: Set<Int64> = [],
    ) {
        self.worksiteId = worksiteId
        self.syncedImageIds = syncedImageIds
        self.unsyncedImageIds = unsyncedImageIds
    }
}
