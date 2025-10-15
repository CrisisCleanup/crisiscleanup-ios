import Combine
import Foundation
import SwiftUI

class WorksiteImagesViewModel: ObservableObject {
    private let worksiteImageRepository: WorksiteImageRepository
    private let localImageRepository: LocalImageRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let accountDataRepository: AccountDataRepository
    private let syncPusher: SyncPusher
    private let translator: KeyTranslator
    private let logger: AppLogger

    private let worksiteId: Int64
    private let imageIdIn: Int64
    private let imageUriIn: String
    let screenTitle: String

    // TODO: Show loading if Case images are being synced
    private let isImageIndexSetGuard = NSLock()
    private var isImageIndexSet = false

    private let imageIndexSubject = CurrentValueSubject<Int, Never>(-1)

    private let isOffline: AnyPublisher<Bool, Never>

    // Decouple selected index to preserve initial matching index value
    private let selectedImageIndexSubject = CurrentValueSubject<Int, Never>(-1)
    @Published private(set) var selectedImageIndex = -1

    @Published private(set) var imageIds = [String]()
    @Published private(set) var caseImages = [CaseImageOrder]()

    @Published private(set) var selectedImageData = caseImageNone
    @Published private(set) var viewState = ViewImageViewState(isLoading: true)

    private let imagesDataSubject = CurrentValueSubject<CaseImagePagerData, Never>(CaseImagePagerData())
    @Published private(set) var imagesData = CaseImagePagerData()

    private let rotatingImagesLock = NSLock()
    private let rotatingImagesSubject = CurrentValueSubject<Set<String>, Never>([])
    @Published private(set) var rotatingImages = Set<String>()
    @Published private(set) var enableRotate = false

    private let deletingImagesLock = NSLock()
    private let deletingImagesSubject = CurrentValueSubject<Set<String>, Never>([])
    @Published private(set) var deletingImages = Set<String>()
    @Published private(set) var isImageDeletable = false
    @Published private(set) var isDeletedImages = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        worksiteImageRepository: WorksiteImageRepository,
        localImageRepository: LocalImageRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        accountDataRepository: AccountDataRepository,
        syncPusher: SyncPusher,
        networkMonitor: NetworkMonitor,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory,
        worksiteId: Int64,
        imageId: Int64,
        imageUri: String,
        screenTitle: String,
    ) {
        self.worksiteImageRepository = worksiteImageRepository
        self.localImageRepository = localImageRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.accountDataRepository = accountDataRepository
        self.syncPusher = syncPusher
        self.translator = translator
        logger = loggerFactory.getLogger("worksite-images")

        self.worksiteId = worksiteId
        imageIdIn = imageId
        imageUriIn = imageUri
        self.screenTitle = translator.t(screenTitle)

        isOffline = networkMonitor.isNotOnline.eraseToAnyPublisher()
    }

    func onViewAppear() {
        subscribeImageIndex()
        subscribeImagesState()
        subscribeViewState()
        subscribeRotateState()
        subscribeDeleteState()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeImageIndex() {
        selectedImageIndexSubject
            .receive(on: RunLoop.main)
            .assign(to: \.selectedImageIndex, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeImagesState() {
        let worksiteImagesPublisher = worksiteId == EmptyWorksite.id
        ? worksiteImageRepository.streamNewWorksiteImages()
        : worksiteImageRepository.streamWorksiteImages(worksiteId)
        let worksiteImages = worksiteImagesPublisher.eraseToAnyPublisher()

        worksiteImages
            .sink { images in
                self.isImageIndexSetGuard.withLock {
                    if images.isNotEmpty,
                       !self.isImageIndexSet {
                        let matchingImageId = self.imageIdIn
                        let matchImageUri = self.imageUriIn
                        for (index, image) in images.enumerated() {
                            if matchingImageId > 0 && matchingImageId == image.id ||
                                image.imageUri.isNotBlank && image.imageUri == matchImageUri {
                                self.isImageIndexSet = true
                                self.imageIndexSubject.value = index
                                self.selectedImageIndexSubject.value = index
                                break
                            }
                        }
                    }
                }
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            imageIndexSubject,
            worksiteImagesPublisher.eraseToAnyPublisher()
        )
        .filter { (_, images) in images.isNotEmpty }
        .map { (index, images) in
            let maxIndex = images.count - 1
            let carouselImageIndex = min(max(0, index), maxIndex)
            let image = carouselImageIndex < images.count ? images[carouselImageIndex] : caseImageNone
            return CaseImagePagerData(
                images: images,
                index: carouselImageIndex,
                imageData: image
            )
        }
        .receive(on: RunLoop.main)
        .assign(to: \.imagesData, on: self)
        .store(in: &subscriptions)

        $imagesData
            .map { data in
                data.images.map { image in
                    image.imageUri
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.imageIds, on: self)
            .store(in: &subscriptions)

        $imagesData
            .map { data in
                data.images.enumerated().map {
                    CaseImageOrder(image: $0.element, index: $0.offset)
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.caseImages, on: self)
            .store(in: &subscriptions)

        $imagesData
            .map { data in
                let index = min(max(0, data.index), data.imageCount)
                let isInBounds = index >= 0 && index < data.images.count
                return isInBounds ? data.images[index] : caseImageNone
            }
            .receive(on: RunLoop.main)
            .assign(to: \.selectedImageData, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeViewState() {
        $selectedImageData
            .compactMap {
                if $0.imageUri.isNotBlank,
                   let imageUrl = URL(string: $0.imageUri) {
                    if $0.isNetworkImage {
                        return ViewImageViewState(
                            imageUrl: imageUrl
                        )
                    } else {
                        let lastPath = imageUrl.lastPathComponent
                        let cached = lastPath.isBlank ? nil : self.localImageRepository.getLocalImage(lastPath)
                        let image = cached == nil ? nil : Image(uiImage: cached!)
                        // TODO: Set error messages if image URL is invalid for network image or image is nil for local image
                        return ViewImageViewState(
                            imageUrl: imageUrl,
                            image: image
                        )
                    }
                }
                return nil
            }
            .receive(on: RunLoop.main)
            .assign(to: \.viewState, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeRotateState() {
        rotatingImagesSubject
            .receive(on: RunLoop.main)
            .assign(to: \.rotatingImages, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $selectedImageData,
            $rotatingImages
        )
        .map { (selected, active) in
            !active.contains(selected.imageUri)
        }
        .receive(on: RunLoop.main)
        .assign(to: \.enableRotate, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeDeleteState() {
        deletingImagesSubject
            .receive(on: RunLoop.main)
            .assign(to: \.deletingImages, on: self)
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            $selectedImageData,
            $deletingImages
        )
        .map { (selected, active) in
            !active.contains(selected.imageUri)
        }
        .receive(on: RunLoop.main)
        .assign(to: \.isImageDeletable, on: self)
        .store(in: &subscriptions)
    }

    func onChangeImageIndex(_ index: Int) {
        if index == imageIndexSubject.value {
            return
        }

        let imageCount = imagesData.imageCount
        imageIndexSubject.value = min(max(0, index), imageCount)
    }

    func onOpenImage(_ index: Int) {
        onChangeImageIndex(index)
        selectedImageIndexSubject.value = imageIndexSubject.value
    }

    private func getMatchingImage(_ imageUri: String) -> CaseImage? {
        imagesData.images.first { image in
            image.imageUri == imageUri
        }
    }

    func rotateImage(_ imageId: String, rotateClockwise: Bool) {
        if let matchingImage = getMatchingImage(imageId) {
            rotatingImagesLock.withLock {
                if rotatingImages.contains(imageId) {
                    return
                }
                var imageIds = self.rotatingImagesSubject.value
                imageIds.insert(imageId)
                rotatingImagesSubject.value = imageIds
            }

            Task {
                do {
                    defer {
                        rotatingImagesLock.withLock {
                            var imageIds = self.rotatingImagesSubject.value
                            imageIds.remove(imageId)
                            rotatingImagesSubject.value = imageIds
                        }
                    }

                    let deltaRotation = rotateClockwise ? 90 : -90
                    let rotation = (matchingImage.rotateDegrees + deltaRotation) % 360
                    self.localImageRepository.setImageRotation(
                        matchingImage.id,
                        matchingImage.isNetworkImage,
                        rotation
                    )
                }
            }
        }
    }

    func deleteImage(_ imageId: String) {
        if let matchingImage = getMatchingImage(imageId) {
            deletingImagesLock.withLock {
                if deletingImages.contains(imageId) {
                    return
                }
                var imageIds = self.deletingImagesSubject.value
                imageIds.insert(imageId)
                deletingImagesSubject.value = imageIds
            }

            Task {
                do {
                    defer {
                        deletingImagesLock.withLock {
                            var imageIds = self.deletingImagesSubject.value
                            imageIds.remove(imageId)
                            deletingImagesSubject.value = imageIds
                        }
                    }

                    let imageCount = caseImages.count
                    if  matchingImage.isNetworkImage {
                        let worksiteId = try worksiteChangeRepository.saveDeletePhoto(matchingImage.id)
                        if worksiteId > 0 {
                            syncPusher.appPushWorksite(worksiteId)
                        }
                    } else {
                        try localImageRepository.deleteLocalImage(matchingImage.id)
                    }

                    Task { @MainActor in
                        if imageCount == 1 {
                            isDeletedImages = true
                        } else {
                            imageIndexSubject.value = max(0, min(imageIndexSubject.value, imageCount - 2))
                            selectedImageIndex = imageIndexSubject.value
                        }
                    }
                } catch {
                    // TODO: Show visual error
                    logger.logError(error)
                }
            }
        }
    }
}

struct CaseImagePagerData {
    let images: [CaseImage]
    let index: Int
    let imageData: CaseImage
    let imageCount: Int

    init(
        images: [CaseImage] = [],
        index: Int = 0,
        imageData: CaseImage = caseImageNone,
        imageCount: Int
    ) {
        self.images = images
        self.index = index
        self.imageData = imageData
        self.imageCount = imageCount
    }

    init(
        images: [CaseImage] = [],
        index: Int = 0,
        imageData: CaseImage = caseImageNone
    ) {
        self.init(
            images: images,
            index: index,
            imageData: imageData,
            imageCount: images.count
        )
    }
}

private let caseImageNone = CaseImage(
    id: 0,
    isNetworkImage: false,
    thumbnailUri: "",
    imageUri: "",
    tag: ""
)

struct CaseImageOrder {
    let image: CaseImage
    let index: Int
}
