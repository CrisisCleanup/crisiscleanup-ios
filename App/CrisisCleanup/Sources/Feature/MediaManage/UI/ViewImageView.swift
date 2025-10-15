import SwiftUI
import CachedAsyncImage

struct ViewImageView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: ViewImageViewModel

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
                        },
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
                        },
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
        .onTapGesture(count: 1) {
            withAnimation {
                showNavBar.toggle()
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onChange(of: viewModel.isDeleted) { isDeleted in
            if isDeleted {
                dismiss()
            }
        }
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
        CachedAsyncImage(url: imageUrl, urlCache: .imageCache) { phase in
            switch phase {
            case .success(let image):
                PanZoomImage(
                    image: image,
                    rotation: rotation,
                    toggleViewDecoration: toggleViewDecoration,
                )
            case .failure(_):
                VStack {
                    Text(t.t("worksiteImages.try_refreshing_open_image"))
                        .foregroundColor(.white)
                        .padding()
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(appTheme.colors.primaryRedColor)
                        .font(.system(size: placeholderImageSize))
                }
            default:
                // TODO: Show loader instead
                Image(systemName: "photo.circle")
                    .foregroundColor(.gray)
                    .font(.system(size: placeholderImageSize))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct PanZoomImage: View {
    private let image: Image

    private let rotation: Double
    private let isRotatedSideways: Bool

    private let toggleViewDecoration: () -> Void

    @State private var imageSize = CGSizeZero
    @State private var imageRotateSize = CGSizeZero
    @State private var screenSize = CGSizeZero

    @State private var imageScales = RectangularScale(
        minScale: 1,
        maxScale: 1,
        fitScale: 1,
        fillScale: 1,
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

        let rotationMod = (rotation + 360) % 360
        self.rotation = Double(rotationMod)
        isRotatedSideways = rotationMod == 90 || rotationMod == 270

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
            imageScales = isRotatedSideways ? fitFillScaleRotate : fitFillScale
        }
    }

    private func capPanOffset(_ delta: CGSize = CGSizeZero) {
        let size = isRotatedSideways ? imageRotateSize : imageSize
        let scaledWidth = size.width * scale
        let scaledHeight = size.height * scale
        var offsetBoundX = max((scaledWidth - screenSize.width) * 0.5, 0)
        var offsetBoundY = max((scaledHeight - screenSize.height) * 0.5, 0)

        if isRotatedSideways {
            let temp = offsetBoundY
            offsetBoundY = offsetBoundX
            offsetBoundX = temp
        }

        let deltaX = delta.width
        let deltaY = delta.height
        let offsetX = max(-offsetBoundX, min(offsetBoundX, offsetCache.x + deltaX))
        let offsetY = max(-offsetBoundY, min(offsetBoundY, offsetCache.y + deltaY))

        offset = CGPoint(x: offsetX, y: offsetY)
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
                                scale = imageScales.fitScale
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
                .scaleEffect(scale)
                .offset(x: offset.x, y: offset.y)
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
                }
                .onTapGesture(count: 1) {
                    toggleViewDecoration()
                }
                .if (scale > imageScales.minScale) {
                    $0.gesture(
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
                }
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
                }
        )
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

    func bound(_ scale: CGFloat) -> CGFloat {
        max(minScale, min(maxScale, scale))
    }
}
