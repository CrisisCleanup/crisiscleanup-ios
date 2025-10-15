import CachedAsyncImage
import SwiftUI

struct WorksiteImagesView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: WorksiteImagesViewModel

    @State private var showPhotosGrid = false

    var body: some View {
        ZStack {
            WorksitePhotosCarousel() {
                withAnimation {
                    showPhotosGrid = true
                }
            }
            if showPhotosGrid {
                // TODO: Common colors
                Color.white.ignoresSafeArea(.all)

                WorksitePhotosGrid() {
                    withAnimation {
                        showPhotosGrid = false
                    }
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .onChange(of: viewModel.isDeletedImages) { newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

private struct WorksitePhotosCarousel: View {
    @EnvironmentObject private var viewModel: WorksiteImagesViewModel

    var onShowGrid: () -> Void = {}

    @State private var isFullscreenMode = false
    @State private var imageTabIndex = 0

    private func syncTabIndex(_ index: Int) {
        if index >= 0,
           index < viewModel.caseImages.count,
           index != imageTabIndex {
            imageTabIndex = index
        }
    }

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
                }
            }
            .onTapGesture(count: 1) {
                withAnimation {
                    isFullscreenMode.toggle()
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
        // onReceive and onChange are needed due to bug and architecture
        // TODO: Rewrite more elegantly
        .onReceive(viewModel.$selectedImageIndex) { index in
            syncTabIndex(index)
        }
        .onChange(of: viewModel.selectedImageIndex) { index in
            syncTabIndex(index)
        }
        .onAppear {
            let selectedIndex = viewModel.selectedImageIndex
            syncTabIndex(selectedIndex)
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

    @State private var viewWidth: CGFloat = 0
    @State private var gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    @State private var gridItemSize = 128.0

    private let gridSpacing = 1.0

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

            ScrollLazyVGrid(
                columns: gridColumns,
                gridItemSpacing: gridSpacing
            ) {
                ForEach(viewModel.caseImages, id: \.index) { caseImageIndex in
                    // TODO: Use converted URLS rather than parsing every time
                    let caseImage = caseImageIndex.image
                    if let imageUrl = URL(string: caseImage.thumbnailUri) {
                        CachedAsyncImage(url: imageUrl, urlCache: .imageCache) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .frame(width: gridItemSize, height: gridItemSize)
                                    .scaledToFill()
                                    .cornerRadius(appTheme.cornerRadius)
                                    .onTapGesture {
                                        viewModel.onOpenImage(caseImageIndex.index)
                                        onBack()
                                    }
                            } else if phase.error != nil {
                                Image(systemName: "exclamationmark.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(appTheme.colors.primaryRedColor)
                                    .padding()
                            } else {
                                Image(systemName: "photo.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                    }
                }
            }
            // TODO: Recalculate on orientation change
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            viewWidth = proxy.size.width
                        }
                }
            }
            .onChange(of: viewWidth) { newValue in
                let columnCount = max(2, Int(ceil(newValue / gridItemSize)))
                if columnCount != gridColumns.count {
                    var columns = [GridItem]()
                    for _ in 0..<columnCount {
                        columns.append(GridItem(.flexible()))
                    }
                    gridColumns = columns
                    gridItemSize = newValue / Double(columnCount)// - (Double(columnCount) + 1) * gridSpacing
                }
            }
        }
    }
}
