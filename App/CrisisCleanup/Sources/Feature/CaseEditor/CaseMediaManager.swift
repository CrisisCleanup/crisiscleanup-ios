import Combine
import Foundation
import PhotosUI
import SwiftUI

class CaseMediaManager: ObservableObject {
    private let localImageRepository: LocalImageRepository
    private let worksiteImageRepository: WorksiteImageRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    private let incidentId: Int64
    private(set) var worksiteId: Int64

    @Published private(set) var beforeAfterPhotos: [ImageCategory: [CaseImage]] = [:]

    @Published private(set) var cachingLocalImageCount: [String: Int] = [:]
    private var localImageCache = [String: UIImage]()

    @Published private(set) var syncingWorksiteImage: Int64 = 0

    private let deletingImageLock = NSLock()
    @Published private(set) var deletingImageIds: Set<String> = []

    private var addImageCategory = ImageCategory.before

    private var isNewWorksite: Bool { worksiteId == EmptyWorksite.id }

    init(
        localImageRepository: LocalImageRepository,
        worksiteImageRepository: WorksiteImageRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        syncPusher: SyncPusher,
        logger: AppLogger,
        incidentId: Int64,
        worksiteId: Int64
    ) {
        self.localImageRepository = localImageRepository
        self.worksiteImageRepository = worksiteImageRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.syncPusher = syncPusher
        self.logger = logger
        self.incidentId = incidentId
        self.worksiteId = worksiteId
    }

    func subscribeLocalImages(_ subscriptions: inout Set<AnyCancellable>) {
        localImageRepository.syncingWorksiteImage
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.syncingWorksiteImage, on: self)
            .store(in: &subscriptions)

        $beforeAfterPhotos
            .sink {
                self.updateImageCache(Array($0.values))
            }
            .store(in: &subscriptions)
    }

    func subscribeCategorizedImages(
        _ imageFiles: any Publisher<[ImageCategory: [CaseImage]], Never>,
        _ subscriptions: inout Set<AnyCancellable>
    ) {
        imageFiles
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.beforeAfterPhotos, on: self)
            .store(in: &subscriptions)
    }

    func updateWorksiteId(_ id: Int64) {
        worksiteId = id
    }

    func updateImageCache(_ categoryImages: [[CaseImage]]) {
        for images in categoryImages {
            images.filter { !$0.isNetworkImage }
                .forEach { localImage in
                    let imageName = localImage.imageName
                    if let cachedImage = self.localImageRepository.getLocalImage(imageName) {
                        self.localImageCache[localImage.imageUri] = cachedImage
                    }
                }
        }
    }

    func setImageCategory(_ category: ImageCategory) {
        addImageCategory = category
    }

    private func updateCachingCount(_ category: ImageCategory, _ delta: Int) {
        let categoryLiteral = category.literal
        let count = cachingLocalImageCount[categoryLiteral] ?? 0
        cachingLocalImageCount[categoryLiteral] = count + delta
    }

    func onMediaSelected(_ results: [PhotosPickerItem]) {
        let category = addImageCategory
        let selectCount = results.count
        updateCachingCount(category, selectCount)
        Task {
            do {
                defer {
                    Task { @MainActor in updateCachingCount(category, -selectCount) }
                }

                if isNewWorksite {
                    try await worksiteImageRepository.queueNewWorksiteImages(incidentId, category.literal, results)
                } else {
                    try await self.localImageRepository.cachePicked(
                        incidentId,
                        worksiteId,
                        category.literal,
                        results
                    )

                    syncPusher.scheduleSyncMedia()
                }
            } catch {
                logger.logError(error)
            }
        }
    }

    func onPhotoTaken(_ result: UIImage) {
        let category = addImageCategory
        updateCachingCount(category, 1)
        Task {
            do {
                defer {
                    Task { @MainActor in updateCachingCount(category, -1) }
                }

                if isNewWorksite {
                    try await worksiteImageRepository.queueNewWorksitePhoto(incidentId, category.literal, result)
                } else {
                    try await self.localImageRepository.cacheImage(
                        incidentId,
                        worksiteId,
                        category.literal,
                        result
                    )

                    syncPusher.scheduleSyncMedia()
                }
            } catch {
                logger.logError(error)
            }
        }
    }

    func getLocalImage(_ imageUri: String) -> UIImage? {
        localImageCache[imageUri]
    }

    func onDeleteImage(_ caseImage: CaseImage) {
        if isNewWorksite {
            worksiteImageRepository.deleteNewWorksiteImage(caseImage.imageUri)
        } else {
            let imageId = caseImage.id
            let imageUri = caseImage.imageUri
            let isDeleting = deletingImageLock.withLock {
                if deletingImageIds.contains(imageUri) {
                    return true
                }
                deletingImageIds.insert(imageUri)
                return false
            }
            if isDeleting {
                return
            }

            Task {
                do {
                    defer {
                        Task { @MainActor in
                            deletingImageLock.withLock {
                                deletingImageIds.remove(imageUri)
                            }
                        }
                    }

                    if caseImage.isNetworkImage {
                        let worksiteId = try worksiteChangeRepository.saveDeletePhoto(imageId)
                        if (worksiteId > 0) {
                            syncPusher.appPushWorksite(worksiteId)
                        }
                    } else {
                        try localImageRepository.deleteLocalImage(imageId)
                    }
                } catch {
                    // TODO: Show error
                    logger.logError(error)
                }
            }
        }
    }
}
