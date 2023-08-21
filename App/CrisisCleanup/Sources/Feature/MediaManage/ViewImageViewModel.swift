import Combine
import Foundation
import SwiftUI

class ViewImageViewModel: ObservableObject {
    private let localImageRepository: LocalImageRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let translator: KeyTranslator
    private let accountDataRepository: AccountDataRepository
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    private let imageId: Int64
    let isNetworkImage: Bool
    let screenTitle: String

    private let isDeletedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isDeleted = false

    let imageRotation = CurrentValueSubject<Int, Never>(0)

    @Published private(set) var uiState = ViewImageUiState(isLoading: true)

    @Published private(set) var isSyncing = false

    @Published private(set) var isImageDeletable = false

    private let isDeletingSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isDeleting = false

    private var savedImageRotation = 999

    private var subscriptions = Set<AnyCancellable>()

    init(
        localImageRepository: LocalImageRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        translator: KeyTranslator,
        accountDataRepository: AccountDataRepository,
        syncPusher: SyncPusher,
        loggerFactory: AppLoggerFactory,
        imageId: Int64,
        isNetworkImage: Bool,
        screenTitle: String
    ) {
        self.localImageRepository = localImageRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.translator = translator
        self.accountDataRepository = accountDataRepository
        self.syncPusher = syncPusher
        logger = loggerFactory.getLogger("view-image")

        self.imageId = imageId
        self.isNetworkImage = isNetworkImage
        self.screenTitle = screenTitle
    }

    func onViewAppear() {
        subscribeToSyncing()
        subscribeToUiState()
        subscribeToImageDelete()
        subscribeToImageRotation()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeToSyncing() {
        localImageRepository.syncingWorksiteImage
            .eraseToAnyPublisher()
            .map { $0 == self.imageId }
            .receive(on: RunLoop.main)
            .assign(to: \.isSyncing, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToUiState() {
        let imageState = isNetworkImage
        ? localImageRepository.streamNetworkImageUrl(imageId)
        : localImageRepository.streamLocalImageUri(imageId)
        imageState
            .compactMap {
                if $0?.isNotBlank == true,
                   let imageUrl = URL(string: $0!) {
                    return imageUrl
                }
                return nil
            }
            .map {
                let lastPath = $0.lastPathComponent
                let cached = lastPath.isBlank ? nil : self.localImageRepository.getLocalImage(lastPath)
                let image = cached == nil ? nil : Image(uiImage: cached!)
                // TODO: Set error messages if image URL is invalid for network image or image is nil for local image
                return ViewImageUiState(
                    imageUrl: $0,
                    image: image
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: \.uiState, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToImageDelete() {
        Publishers.CombineLatest3(
            $uiState.eraseToAnyPublisher(),
            $isSyncing.eraseToAnyPublisher(),
            $isDeleting.eraseToAnyPublisher()
        )
        .map { (state, syncing, deleting) in
            state.imageUrl != nil &&
            self.imageId > 0 &&
            !(syncing || deleting)
        }
        .receive(on: RunLoop.main)
        .assign(to: \.isImageDeletable, on: self)
        .store(in: &subscriptions)

        isDeletingSubject
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isDeleting, on: self)
            .store(in: &subscriptions)

        isDeletedSubject
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isDeleted, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToImageRotation() {
        imageRotation
            .debounce(
                for: .seconds(0.25),
                scheduler: RunLoop.current
            )
            .removeDuplicates()
            .sink(receiveValue: { rotation in
                if self.savedImageRotation < 999 {
                    self.localImageRepository.setImageRotation(
                        self.imageId,
                        self.isNetworkImage,
                        rotation
                    )
                }
            })
            .store(in: &subscriptions)

        Task {
            let rotation = localImageRepository.getImageRotation(imageId, isNetworkImage)
            Task { @MainActor in
                if rotation != imageRotation.value {
                    imageRotation.value = rotation
                }
                self.savedImageRotation = rotation
            }
        }
    }

    func deleteImage() {
        isDeletingSubject.value = true
        Task {
            do {
                defer { isDeletingSubject.value = false }

                if (isNetworkImage) {
                    let worksiteId = try worksiteChangeRepository.saveDeletePhoto(imageId)
                    if worksiteId > 0 {
                        syncPusher.appPushWorksite(worksiteId)
                    }
                } else {
                    try localImageRepository.deleteLocalImage(imageId)
                }
                isDeletedSubject.value = true
            } catch {
                // TODO: Show error
                logger.logError(error)
            }
        }
    }

    func rotateImage(_ rotateClockwise: Bool) {
        imageRotation.value = imageRotation.value + (rotateClockwise ? 90 : -90) % 360
    }
}

struct ViewImageUiState {
    let isLoading: Bool
    let imageUrl: URL?
    let image: Image?
    let errorMessage: String

    init(
        isLoading: Bool = false,
        imageUrl: URL? = nil,
        image: Image? = nil,
        errorMessage: String = ""
    ) {
        self.isLoading = isLoading
        self.imageUrl = imageUrl
        self.image = image
        self.errorMessage = errorMessage
    }
}
