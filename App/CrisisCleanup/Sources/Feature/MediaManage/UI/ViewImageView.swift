import SwiftUI
import CachedAsyncImage

struct ViewImageView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: ViewImageViewModel

    @State var showNavBar: Bool = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)

            if viewModel.uiState.isLoading {
                VStack {
                    ProgressView()
                        .frame(alignment: .center)
                }
            }

            if let imageUrl = viewModel.uiState.imageUrl {
                if viewModel.isNetworkImage {
                    ViewNetworkImage(
                        imageUrl: imageUrl,
                        toggleNavBar: {
                            withAnimation {
                                showNavBar.toggle()
                            }
                        }
                    )
                } else {
                    // TODO: Do
                }
            }

            if(showNavBar) {
                ImageNav(
                    navTitle: viewModel.screenTitle,
                    isDeletable: viewModel.isImageDeletable,
                    deleteImage: { viewModel.deleteImage() }
                )
            }
        }
        .onTapGesture(count: 1) {
            if !viewModel.uiState.isLoading {
                withAnimation {
                    showNavBar.toggle()
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onReceive(viewModel.$isDeleted) { isDeleted in
            if isDeleted {
                dismiss()
            }
        }
    }
}

struct ImageNav: View {
    @Environment(\.dismiss) var dismiss

    let navTitle: String
    let isDeletable: Bool
    let deleteImage: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }

                Spacer()

                Text(navTitle)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    deleteImage()
                } label: {
                    let color: Color = isDeletable ? .white : .white.opacity(0.5)
                    Image(systemName: "trash.fill")
                        .foregroundColor(color)
                }
                .disabled(!isDeletable)
            }
            .padding()
            .background(
                // TODO: Improve the smoothness of the gradient
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.5), .black.opacity(0.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onTapGesture(count: 1) {
                // Consume
            }

            Spacer()
        }
    }
}

private struct ViewNetworkImage: View {
    let imageUrl: URL

    let toggleNavBar: () -> Void

    let placeholderImageSize = 128.0

    var body: some View {
        CachedAsyncImage(url: imageUrl) { phase in
            if let image = phase.image {
                PanZoomImage(
                    image: image,
                    toggleNavBar: toggleNavBar
                )
            } else if phase.error != nil {
                VStack {
                    // TODO: Translation
                    Text("~~Try refreshing and opening the image again.")
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

private struct PanZoomImage: View {
    let image: Image

    let toggleNavBar: () -> Void

    @State private var scale: CGFloat = 1.0
    @State var offset = CGPoint(x: 0, y: 0)
    @State var offsetCache = CGPoint(x: 0, y: 0)
    @State var imgSize: CGSize = CGSizeZero
    @State var screenSize: CGSize = CGSizeZero

    var body: some View {
        ZStack
        {
            Color.black.ignoresSafeArea(.all)
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                screenSize = proxy.size
                            }
                    }.ignoresSafeArea(.all)
                )

            image
                .resizable()
                .scaledToFit()
                .onTapGesture(count: 2) {
                    if(scale > 1) {
                        scale = 1
                        offset = CGPointZero
                    } else {
                        scale = screenSize.height/imgSize.height
                    }
                }
                .onTapGesture(count: 1) {
                    toggleNavBar()
                }
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                imgSize = proxy.size
                            }
                    }
                )
                .scaleEffect(scale)
                .offset(x: offset.x, y: offset.y)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if imgSize.height*scale > screenSize.height {
                                let maxYOffset = (imgSize.height*scale - screenSize.height)/2
                                let addedYOffset = offsetCache.y + value.translation.height
                                if(abs(addedYOffset) > maxYOffset) {
                                    offset.y = addedYOffset > 0 ? maxYOffset : -maxYOffset
                                } else {
                                    offset.y = addedYOffset
                                }
                            }
                            let maxXOffset = (imgSize.width*scale - imgSize.width)/2
                            if(abs(offset.x) <= maxXOffset)
                            {
                                let addedXOffset = offsetCache.x + value.translation.width
                                if(abs(addedXOffset) > maxXOffset) {
                                    offset.x = addedXOffset > 0 ? maxXOffset : -maxXOffset
                                } else {
                                    offset.x = addedXOffset
                                }
                            }
                        }
                        .onEnded({ value in
                            offsetCache = offset
                        })
                )
        }
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { newScale in
                    if newScale >= 1 {
                        scale = newScale > 5 ? 5: newScale.magnitude
                    } else if (scale > 1 && newScale < 1) {
                        if (newScale.magnitude < 1) {
                            scale = 1 // limits scaling to 1
                        } else {
                            scale = newScale.magnitude
                        }
                    }
                }
        )
        .onTapGesture(count: 2) {
            if(scale > 1) {
                scale = 1
                offset = CGPointZero
            } else {
                scale = screenSize.height/imgSize.height
            }
        }
    }
}
