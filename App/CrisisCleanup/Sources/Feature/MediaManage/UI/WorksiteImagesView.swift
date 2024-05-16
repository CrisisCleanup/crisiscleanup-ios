import SwiftUI

struct WorksiteImagesView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: WorksiteImagesViewModel
    @ObservedObject private var disablePaging = PageableTabView()

    @State private var showPhotosGrid = false

    var body: some View {
        ZStack {
            if showPhotosGrid {
                WorksitePhotosGrid() {
                    withAnimation {
                        showPhotosGrid = false
                    }
                }
            } else {
                WorksitePhotosCarousel() {
                    withAnimation {
                        showPhotosGrid = true
                    }
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .environmentObject(disablePaging)
        .onChange(of: viewModel.isDeletedImages) { newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

private struct WorksitePhotosCarousel: View {
    @EnvironmentObject private var viewModel: WorksiteImagesViewModel
    @EnvironmentObject var disablePaging: PageableTabView

    var onShowGrid: () -> Void = {}

    @State private var isFullscreenMode = false
    @State private var imageTabIndex = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea(.all)

            if viewModel.viewState.isLoading {
                ProgressView()
                    .frame(alignment: .center)
                // TODO: Common colors
                    .tint(.white)
            }

            let viewState = viewModel.viewState
            let selectedImage = viewModel.selectedImageData
            TabView(selection: $imageTabIndex) {
                ForEach(viewModel.caseImages, id: \.index) { caseImageIndex in
                    let caseImage = caseImageIndex.image
                    let index = caseImageIndex.index

                    ZStack {
                        if caseImage.imageUri == selectedImage.imageUri {
                            Group {
                                if let image = viewState.image {
                                    PanZoomImage(
                                        image: image,
                                        rotation: selectedImage.rotateDegrees
                                    ) {
                                        withAnimation {
                                            isFullscreenMode.toggle()
                                        }
                                    }
                                } else if let imageUrl = viewState.imageUrl {
                                    UrlImageView(
                                        imageUrl: imageUrl,
                                        rotation: selectedImage.rotateDegrees
                                    ) {
                                        withAnimation {
                                            isFullscreenMode.toggle()
                                        }
                                    }
                                } else {
                                    // TODO: Message for corrective actions (from view model)
                                }
                            }
                            .id("worksite-photo-\(selectedImage.imageUri)-\(selectedImage.rotateDegrees)")
                        }
                    }
                    .tag(index)
                    .simultaneousGesture(disablePaging.disablePaging ? DragGesture() : nil)
                }
            }
            .tabViewStyle(.page)
            .ignoresSafeArea()
            .onChange(of: imageTabIndex) { newValue in
                viewModel.onChangeImageIndex(newValue)
            }

            if !isFullscreenMode {
                SingleImageViewDecoration(
                    imageId: viewState.imageUrl?.absoluteString ?? "",
                    showRotateActions: selectedImage.id > 0,
                    onShowGrid: onShowGrid
                )
            }
        }
        .onChange(of: viewModel.selectedImageIndex) { index in
            if index>=0 && index<viewModel.caseImages.count {
                imageTabIndex = index
            }
        }
        // TODO: Not working. Likely due to root view structure. Simplify and debug.
        .statusBar(hidden: isFullscreenMode)
    }
}

private struct SingleImageViewDecoration: View {
    @EnvironmentObject private var viewModel: WorksiteImagesViewModel

    let imageId: String

    let showRotateActions: Bool

    var onShowGrid: () -> Void = {}

    var body: some View {
        VStack {
            ViewImageTopBarNav(
                navTitle: viewModel.screenTitle,
                isDeletable: viewModel.isImageDeletable,
                deleteImage: { viewModel.deleteImage(imageId) }
            )

            Spacer()

            let disableRotateActions = !viewModel.enableRotate
            let showGridAction = viewModel.caseImages.count > 1
            HStack {
                if showGridAction {
                    Image(systemName: "photo.fill.on.rectangle.fill")
                        .hidden()
                }

                Spacer()

                if showRotateActions {
                    Button {
                        viewModel.rotateImage(imageId, rotateClockwise: false)
                    } label: {
                        Image(systemName: "rotate.left.fill")
                            .disabled(disableRotateActions)
                    }

                    Rectangle()
                        .foregroundColor(.clear)
                    // TODO: Common dimensions
                        .frame(width: 16, height: 1)

                    Button {
                        viewModel.rotateImage(imageId, rotateClockwise: true)
                    } label: {
                        Image(systemName: "rotate.right.fill")
                            .disabled(disableRotateActions)
                    }

                    Spacer()
                }

                if showGridAction {
                    Button {
                        onShowGrid()
                    } label: {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                    }
                }
            }
            .padding()
            .background(.white)
            .cornerRadius(appTheme.cornerRadius)
            .padding()
        }
    }
}

private struct WorksitePhotosGrid: View {
    @EnvironmentObject private var viewModel: WorksiteImagesViewModel

    var onBack: () -> Void = {}

    var body: some View {
        VStack {
            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(viewModel.screenTitle)
                    .fontHeader3()

                Spacer()

                // Spacer
                Image(systemName: "chevron.left")
                    .hidden()
            }
            .padding()

            Spacer()
            Text("Show photos grid")
            Spacer()
        }
    }
}
