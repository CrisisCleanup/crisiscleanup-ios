import Combine
import Foundation
import PhotosUI
import SwiftUI

public protocol WorksiteImageRepository {
    var hasNewWorksiteImages: Bool { get }

    func clearNewWorksiteImages()

    func streamNewWorksiteImages() -> any Publisher<[CaseImage], Never>
    func streamWorksiteImages(_ worksiteId: Int64) -> any Publisher<[CaseImage], Never>

    func queueNewWorksiteImages(
        _ incidentId: Int64,
        _ tag: String,
        _ picked: [PhotosPickerItem]
    ) async throws

    func queueNewWorksitePhoto(
        _ incidentId: Int64,
        _ tag: String,
        _ image: UIImage
    ) async throws

    func deleteNewWorksiteImage(_ uri: String)
    func transferNewWorksiteImages(_ worksiteId: Int64) async
}

class OfflineFirstWorksiteImageRepository: WorksiteImageRepository {
    private let worksiteDao: WorksiteDao
    private let localImageDao: LocalImageDao
    private let localImageRepository: LocalImageRepository
    private let localFileCache: LocalFileCache
    private let logger: AppLogger

    private let newWorksiteImagesSubject = CurrentValueSubject<[WorksiteLocalImage], Never>([])
    private var newWorksiteImagesCache = [String: WorksiteLocalImage]()
    private let newWorksiteImagesLock = NSLock()

    var hasNewWorksiteImages: Bool { newWorksiteImagesCache.isNotEmpty }

    init(
        worksiteDao: WorksiteDao,
        localImageDao: LocalImageDao,
        localImageRepository: LocalImageRepository,
        localFileCache: LocalFileCache,
        loggerFactory: AppLoggerFactory
    ) {
        self.worksiteDao = worksiteDao
        self.localImageDao = localImageDao
        self.localImageRepository = localImageRepository
        self.localFileCache = localFileCache
        logger = loggerFactory.getLogger("worksite-image-repository")
    }

    func clearNewWorksiteImages() {
        newWorksiteImagesLock.withLock {
            newWorksiteImagesCache = [:]
            newWorksiteImagesSubject.value = []
        }
    }

    func streamNewWorksiteImages() -> any Publisher<[CaseImage], Never> {
        newWorksiteImagesSubject.map {
            $0.map { $0.asCaseImage() }
        }
    }

    func streamWorksiteImages(_ worksiteId: Int64) -> any Publisher<[CaseImage], Never> {
        worksiteDao.streamWorksiteFiles(worksiteId)
            .assertNoFailure()
            .map { $0?.toCaseImages() ?? [] }
    }

    private func cacheNewLocalImages(
        _ cached: [String: String],
        _ tag: String
    ) {
        var images = [WorksiteLocalImage]()
        for (fileId, imageLocalUri) in cached {
            let localWorksiteImage = WorksiteLocalImage(
                id: 0,
                worksiteId: EmptyWorksite.id,
                documentId: fileId,
                uri: imageLocalUri,
                tag: tag
            )
            images.append(localWorksiteImage)
        }

        for image in images {
            newWorksiteImagesLock.withLock {
                newWorksiteImagesCache[image.documentId] = image
                newWorksiteImagesSubject.value = Array(newWorksiteImagesCache.values)
            }
        }
    }

    func queueNewWorksiteImages(
        _ incidentId: Int64,
        _ tag: String,
        _ picked: [PhotosPickerItem]
    ) async throws {
        let worksiteId = EmptyWorksite.id
        let cached = try await localFileCache.cachePicked(incidentId, worksiteId, picked)
        cacheNewLocalImages(cached, tag)
    }

    func queueNewWorksitePhoto(
        _ incidentId: Int64,
        _ tag: String,
        _ image: UIImage
    ) async throws {
        let worksiteId = EmptyWorksite.id
        let cached = try await localFileCache.cacheImage(incidentId, worksiteId, image)
        cacheNewLocalImages(cached, tag)
    }

    func deleteNewWorksiteImage(_ uri: String) {
        newWorksiteImagesLock.withLock {
            if let _ = newWorksiteImagesCache.removeValue(forKey: uri) {
                newWorksiteImagesSubject.value = Array(newWorksiteImagesCache.values)
            }
        }
    }

    func transferNewWorksiteImages(_ worksiteId: Int64) async {
        var images = [WorksiteLocalImage]()
        newWorksiteImagesLock.withLock {
            images = Array(newWorksiteImagesCache.values)
        }

        do {
            let copyImages = images.map { image in
                return image.copy { $0.worksiteId = worksiteId }
            }
            let recordImages = copyImages.map { $0.asRecord() }
            // TODO: Write test
            try localImageDao.upsertLocalImages(recordImages)

            clearNewWorksiteImages()
        } catch {
            logger.logError(error)
        }
    }
}
