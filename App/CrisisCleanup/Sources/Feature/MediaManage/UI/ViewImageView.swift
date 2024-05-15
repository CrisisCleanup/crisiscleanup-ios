import SwiftUI
import CachedAsyncImage

struct ViewImageView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: ViewImageViewModel
    @ObservedObject private var disablePaging = PageableTabView()

    @State private var showNavBar = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)

            if viewModel.viewState.isLoading {
                ProgressView()
                    .frame(alignment: .center)
                // TODO: Common colors
                    .tint(.white)
            }

            if viewModel.isNetworkImage {
                if let imageUrl = viewModel.viewState.imageUrl {
                    UrlImageView(
                        imageUrl: imageUrl,
                        toggleViewDecoration: {
                            withAnimation {
                                showNavBar.toggle()
                            }
                        }
                    )
                } else {
                    // TODO: Message for corrective actions (from view model)
                }
            } else {
                if let image = viewModel.viewState.image {
                    PanZoomImage(
                        image: image,
                        toggleViewDecoration: {
                            withAnimation {
                                showNavBar.toggle()
                            }
                        }
                    )
                } else {
                    // TODO: Message that image may have been deleted by system. Will need to reselect to upload
                }
            }

            if showNavBar {
                ViewImageTopBarNav(
                    navTitle: viewModel.screenTitle,
                    isDeletable: viewModel.isImageDeletable,
                    deleteImage: { viewModel.deleteImage() }
                )
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onChange(of: viewModel.isDeleted) { isDeleted in
            if isDeleted {
                dismiss()
            }
        }
        .environmentObject(disablePaging)
    }
}

struct ViewImageTopBarNav: View {
    @Environment(\.dismiss) var dismiss

    let navTitle: String
    let isDeletable: Bool
    let deleteImage: () -> Void

    let onNavBack: (() -> Void)? = nil

    var body: some View {
        VStack {
            HStack {
                Button {
                    if let backAction = onNavBack {
                        backAction()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(navTitle)
                    .fontHeader3()

                Spacer()

                Button {
                    deleteImage()
                } label: {
                    Image(systemName: "trash.fill")
                }
                .disabled(!isDeletable)
            }
            .padding()
            .background(.white)
            .onTapGesture(count: 1) {
                // Consume
            }

            Spacer()
        }
    }
}

struct UrlImageView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let imageUrl: URL
    var rotation = 0

    let toggleViewDecoration: () -> Void

    let placeholderImageSize = 128.0

    var body: some View {
        CachedAsyncImage(url: imageUrl) { phase in
            if let image = phase.image {
                PanZoomImage(
                    image: image,
                    rotation: rotation,
                    toggleViewDecoration: toggleViewDecoration
                )
            } else if phase.error != nil {
                VStack {
                    Text(t.t("worksiteImages.try_refreshing_open_image"))
                        .foregroundColor(.white)
                        .padding()
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(appTheme.colors.primaryRedColor)
                        .font(.system(size: placeholderImageSize))
                }
            } else {
                // TODO: Show loader instead
                Image(systemName: "photo.circle")
                    .foregroundColor(.gray)
                    .font(.system(size: placeholderImageSize))
            }                }
        .edgesIgnoringSafeArea(.all)
    }
}

struct PanZoomImage: View {
    @EnvironmentObject var disablePaging: PageableTabView

    private let image: Image

    private let rotation: Double
    private let isRotated: Bool

    private let toggleViewDecoration: () -> Void

    @State private var imageSize = CGSizeZero
    @State private var imageRotateSize = CGSizeZero
    @State private var screenSize = CGSizeZero

    @State private var imageScales = RectangularScale(
        minScale: 1,
        maxScale: 1,
        fitScale: 1,
        fillScale: 1
    )
    @State private var scale: CGFloat = 1.0
    @State private var scaleCache: CGFloat = 1.0

    @State private var offset = CGPointZero
    @State private var offsetCache = CGPointZero

    init(
        image: Image,
        rotation: Int = 0,
        toggleViewDecoration: @escaping () -> Void
    ) {
        self.image = image

        self.rotation = Double(rotation)
        isRotated = rotation != 0

        self.toggleViewDecoration = toggleViewDecoration
    }

    private func getFitFillScale(
        size: CGSize,
        fullSize: CGSize,
        isRotated: Bool
    ) -> RectangularScale {
        let normalizedWidth = fullSize.width / size.width
        let normalizedHeight = fullSize.height / size.height
        let fitScale = min(normalizedWidth, normalizedHeight)
        let fillScale = max(normalizedWidth, normalizedHeight)
        return RectangularScale(
            minScale: fitScale,
            maxScale: fillScale * 10,
            fitScale: fitScale,
            fillScale: fillScale
        )
    }

    private func setScales() {
        if imageSize != CGSizeZero,
           screenSize != CGSizeZero,
           imageRotateSize == CGSizeZero {
            imageRotateSize = CGSize(width: imageSize.height, height: imageSize.width)
            let fitFillScale = getFitFillScale(size: imageSize, fullSize: screenSize, isRotated: false)
            let fitFillScaleRotate = getFitFillScale(size: imageRotateSize, fullSize: screenSize, isRotated: true)
            imageScales = isRotated ? fitFillScaleRotate : fitFillScale
        }
    }

    private func capPanOffset(_ delta: CGSize = CGSizeZero) {
        let size = isRotated ? imageRotateSize : imageSize
        let scaledWidth = size.width * scale
        let scaledHeight = size.height * scale
        var deltaX = max((scaledWidth - screenSize.width) * 0.5, 0)
        var deltaY = max((scaledHeight - screenSize.height) * 0.5, 0)
        deltaX = max(-deltaX, min(deltaX, offsetCache.x + delta.width))
        deltaY = max(-deltaY, min(deltaY, offsetCache.y + delta.height))
        offset = CGPoint(x: deltaX, y: deltaY)
    }

    private func updateSwipeState() {
        disablePaging.disablePaging = scale > imageScales.minScale
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                screenSize = proxy.size
                                setScales()
                            }
                    }
                        .ignoresSafeArea(.all)
                )

            image
                .resizable()
                .scaledToFit()
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                imageSize = proxy.size
                                setScales()
                            }
                    }
                )
                .onTapGesture(count: 2) {
                    if offset == CGPointZero {
                        if scale == imageScales.fitScale {
                            scale = imageScales.fillScale
                        } else if scale == imageScales.fillScale {
                            scale = imageScales.fitScale
                        } else {
                            scale = imageScales.snapToNearest(scale)
                        }
                    } else {
                        scale = imageScales.snapToNearest(scale)
                        offset = CGPointZero
                    }
                    scaleCache = scale
                    updateSwipeState()
                }
                .onTapGesture(count: 1) {
                    toggleViewDecoration()
                }
                .scaleEffect(scale)
                .offset(x: offset.x, y: offset.y)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            // TODO: Apply velocity

                            let delta = gesture.translation
                            capPanOffset(delta)
                        }
                        .onEnded { value in
                            offsetCache = offset
                        }
                )
                .rotationEffect(.degrees(rotation))
        }
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { magnitude in
                    scale = imageScales.bound(scaleCache * magnitude)
                    capPanOffset()
                }
                .onEnded { _ in
                    scaleCache = scale
                    updateSwipeState()
                }
        )
        .onTapGesture(count: 1) {
            toggleViewDecoration()
        }
    }
}

private struct RectangularScale {
    let minScale: CGFloat
    let maxScale: CGFloat
    let fitScale: CGFloat
    let fillScale: CGFloat

    func snapToNearest(_ scale: CGFloat) -> CGFloat {
        scale - fitScale < fillScale - scale ? fitScale : fillScale
    }

    func bound(_ scale: CGFloat) ->CGFloat {
        max(minScale, min(maxScale, scale))
    }
}

class PageableTabView: ObservableObject {
    @Published var disablePaging = false
}
