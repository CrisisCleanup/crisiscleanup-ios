import Combine
import Foundation
import PhotosUI
import SwiftUI

class CaseMediaManager: ObservableObject {
    private let localImageRepository: LocalImageRepository
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    private let incidentId: Int64
    private let worksiteId: Int64

    @Published private(set) var beforeAfterPhotos: [ImageCategory: [CaseImage]] = [:]

    @Published private(set) var cachingLocalImageCount: [String: Int] = [:]
    private var localImageCache = [String: UIImage]()

    @Published private(set) var syncingWorksiteImage: Int64 = 0

    @Published private(set) var deletingImageIds: Set<Int64> = []

    private var addImageCategory = ImageCategory.before

    init(
        localImageRepository: LocalImageRepository,
        syncPusher: SyncPusher,
        logger: AppLogger,
        incidentId: Int64,
        worksiteId: Int64
    ) {
        self.localImageRepository = localImageRepository
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
            .sink(receiveValue: {
                self.updateImageCache(Array($0.values))
            })
            .store(in: &subscriptions)
    }

    func subscribeImageFiles(
        _ imageFiles: any Publisher<([CaseImage], [CaseImage]), Never>,
        _ subscriptions: inout Set<AnyCancellable>
    ) {
        imageFiles
            .eraseToAnyPublisher()
            .map { (files, localFiles) in
                let beforeImages = Array([
                    localFiles.filter { !$0.isAfter },
                    files.filter { !$0.isAfter }
                ].joined())
                let afterImages = Array([
                    localFiles.filter { $0.isAfter },
                    files.filter { $0.isAfter }
                ].joined())
                return [
                    ImageCategory.before: beforeImages,
                    ImageCategory.after: afterImages
                ]
            }
            .receive(on: RunLoop.main)
            .assign(to: \.beforeAfterPhotos, on: self)
            .store(in: &subscriptions)
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

    func onMediaSelected(_ results: [PhotosPickerItem]) {
        let categoryLiteral = addImageCategory.literal
        let count = cachingLocalImageCount[categoryLiteral] ?? 0
        let selectCount = results.count
        cachingLocalImageCount[categoryLiteral] = count + selectCount

        Task {
            do {
                defer {
                    Task { @MainActor in
                        let cachingCount = cachingLocalImageCount[categoryLiteral] ?? 0
                        cachingLocalImageCount[categoryLiteral] = cachingCount - selectCount
                    }
                }

                try await self.localImageRepository.cachePicked(
                    incidentId,
                    worksiteId,
                    categoryLiteral,
                    results
                )

                syncPusher.scheduleSyncMedia()
            } catch {
                logger.logError(error)
            }
        }
    }

    func onPhotoTaken(_ result: UIImage) {
        let categoryLiteral = addImageCategory.literal
        let count = cachingLocalImageCount[categoryLiteral] ?? 0
        cachingLocalImageCount[categoryLiteral] = count + 1

        Task {
            do {
                defer {
                    Task { @MainActor in
                        let cachingCount = cachingLocalImageCount[categoryLiteral] ?? 0
                        cachingLocalImageCount[categoryLiteral] = cachingCount - 1
                    }
                }

                try await self.localImageRepository.cacheImage(
                    incidentId,
                    worksiteId,
                    categoryLiteral,
                    result
                )

                syncPusher.scheduleSyncMedia()
            } catch {
                logger.logError(error)
            }
        }
    }

    func getPhotoImages(_ category: ImageCategory) -> [CaseImage]? {
        beforeAfterPhotos[category]
    }

    func getLocalImage(_ imageUri: String) -> UIImage? {
        localImageCache[imageUri]
    }

    func onDeleteImage(_ caseImage: CaseImage) {
        print("Delete image \(caseImage)")
    }
}
