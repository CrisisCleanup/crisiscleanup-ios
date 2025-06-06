import CachedAsyncImage
import PhotosUI
import SwiftUI

struct ViewCasePhotosView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var caseMediaManager: CaseMediaManager

    let headerTitle: String

    var isCompactLayout = false

    @Binding var areOptionsOpen: Bool

    @State private var photoDetents = false
    @State private var presentCamera = false
    @State private var takePhotoImage = UIImage()
    @State private var results = [PhotosPickerItem]()

    private func onTakePhotoSelectImage(_ category: ImageCategory) {
        caseMediaManager.setImageCategory(category)
        photoDetents.toggle()
    }

    var body: some View {
        VStack (alignment: .leading) {
            ViewCasePhotosSection(
                headerTitle: headerTitle,
                category: .before,
                isCompactLayout: isCompactLayout,
                onTakePhotoSelectImage: onTakePhotoSelectImage
            )
            ViewCasePhotosSection(
                headerTitle: headerTitle,
                category: .after,
                isCompactLayout: isCompactLayout,
                onTakePhotoSelectImage: onTakePhotoSelectImage
            )

            Spacer()
        }
        .onChange(of: results) { _ in
            photoDetents = false
            caseMediaManager.onMediaSelected(results)
            results = []
        }
        .sheet(isPresented: $photoDetents) {
            ZStack {
                VStack {
                    Button {
                        presentCamera.toggle()
                    } label : {
                        Text(t.t("actions.take_photo"))
                            .padding()
                    }
                    .tint(.black)
                    .sheet(isPresented: $presentCamera) {
                        ImagePickerCamera(selectedImage: $takePhotoImage)
                    }
                    .onChange(of: takePhotoImage) { newValue in
                        if newValue.size != .zero {
                            caseMediaManager.onPhotoTaken(newValue)
                            takePhotoImage = UIImage()
                            photoDetents = false
                        }
                    }

                    PhotosPicker(
                        selection: $results,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text(t.t("fileUpload.select_file_upload"))
                            .padding()
                    }
                    .tint(.black)

                }
            }
            .presentationDetents([.medium, .fraction(0.25)])
        }
        .environmentObject(caseMediaManager)
        .onChange(of: photoDetents) { newValue in
            areOptionsOpen = newValue
        }
    }
}

private struct ViewCasePhotosSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let headerTitle: String
    var category: ImageCategory

    var isCompactLayout = false

    var onTakePhotoSelectImage: (ImageCategory) -> Void = {_ in}

    var body: some View {
        let sectionTranslateKey = category == .before
        ? "caseForm.before_photos"
        : "caseForm.after_photos"
        let sectionTitle = t.t(sectionTranslateKey)
        if !isCompactLayout {
            Text(sectionTitle)
                .fontHeader4()
                .padding(.leading, appTheme.gridItemSpacing)
                .padding(.top)
        }

        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, content: {
                MediaDisplay(
                    headerTitle: headerTitle,
                    category: category,
                    sectionTitle: isCompactLayout ? sectionTitle : "",
                    onTakePhotoSelectImage: onTakePhotoSelectImage
                )
            })
        }
        .frame(minHeight: 120, maxHeight: 180)
    }
}

private struct DeleteContextMenu: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let onDelete: () -> Void
    var padding: CGFloat = 8.0

    var body: some View {
        Menu {
            Button(t.t("actions.delete")) {
                onDelete()
            }
        } label: {
            Image(systemName: "ellipsis")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .padding(4)
                .background(.white.opacity(0.5))
                .clipShape(Circle())
                .padding(padding)
        }
    }
}

private struct MediaDisplay: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var caseMediaManager: CaseMediaManager

    var headerTitle: String
    var category: ImageCategory
    var sectionTitle = ""
    var onTakePhotoSelectImage: (ImageCategory) -> Void = {_ in}

    @State var mediaImages: [Image] = []

    func openViewImage(_ caseImage: CaseImage) {
        router.openWorksiteImages(
            worksiteId: caseMediaManager.worksiteId,
            imageId: caseImage.id,
            imageUri: caseImage.imageUri,
            screenTitle: headerTitle
        )
    }

    var body: some View {
        let beforeAfterImages = caseMediaManager.beforeAfterPhotos[category] ?? []
        let iconFont = Font.system(size: 16.0)

        Rectangle()
            .fill(.clear)
            .frame(width: 0.1)

        if sectionTitle.isNotBlank {
            Text(sectionTitle.replacingOccurrences(of: " ", with: "\n"))
                .fontHeader4()
                .listItemPadding()
        }

        let r = appTheme.cornerRadius
        ZStack {
            let strokeColor = appTheme.colors.primaryBlueColor
            let cornerSize = CGSize(width: r, height: r)
            RoundedRectangle(cornerSize: cornerSize)
                .fill(appTheme.colors.addMediaBackgroundColor)
                .frame(width: 120)
                .overlay {
                    RoundedRectangle(cornerSize: cornerSize)
                        .stroke(strokeColor, style: StrokeStyle(lineWidth: 2, dash: [5]))
                }

            VStack {
                Image(systemName: "plus")
                    .foregroundColor(strokeColor)
                Text(t.t("actions.add_media"))
                    .foregroundColor(strokeColor)
            }
        }
        .padding(.vertical, r * 0.55)
        .onTapGesture {
            onTakePhotoSelectImage(category)
        }

        let cachingImageCount = caseMediaManager.cachingLocalImageCount[category.literal] ?? 0
        ForEach(0..<cachingImageCount, id: \.self) { index in
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundColor(appTheme.colors.addMediaBackgroundColor)
                .font(iconFont)
        }

        let deletingImageIds = caseMediaManager.deletingImageIds
        ForEach(beforeAfterImages, id: \.imageUri) { caseImage in
            let isDeleting = deletingImageIds.contains(caseImage.imageUri)
            let deleteImage = {
                caseMediaManager.onDeleteImage(caseImage)
            }

            if caseImage.isNetworkImage {
                let imageUrl = URL(string: caseImage.thumbnailUri)
                CachedAsyncImage(url: imageUrl, urlCache: .imageCache) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(appTheme.cornerRadius)
                            .onTapGesture {
                                if !isDeleting {
                                    openViewImage(caseImage)
                                }
                            }
                            .overlay(alignment: .topTrailing) {
                                if !isDeleting {
                                    DeleteContextMenu(onDelete: deleteImage)
                                }
                            }
                    } else if phase.error != nil {
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                if !isDeleting {
                                    openViewImage(caseImage)
                                }
                            }
                            .foregroundColor(appTheme.colors.primaryRedColor)
                            .padding()
                    } else {
                        Image(systemName: "photo.circle")
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                if !isDeleting {
                                    openViewImage(caseImage)
                                }
                            }
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            } else {
                if let image = caseMediaManager.getLocalImage(caseImage.imageUri) {
                    let syncingWorksiteImage = caseMediaManager.syncingWorksiteImage
                    let isSyncing = syncingWorksiteImage != 0 && syncingWorksiteImage == caseImage.id
                    let isTransient = isSyncing || isDeleting
                    let alignment: Alignment = isTransient ? .center : .topTrailing
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(appTheme.cornerRadius)
                        .onTapGesture { openViewImage(caseImage) }
                        .overlay(alignment: alignment) {
                            if isTransient {
                                Image(systemName: "cloud.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 48, height: 48)
                                    .padding()
                                    .background(.white.opacity(0.8))
                                    .clipShape(Circle())
                            } else {
                                HStack {
                                    Image(systemName: "cloud.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                        .padding(4)
                                        .background(.white.opacity(0.5))
                                        .clipShape(Circle())

                                    if !isDeleting {
                                        DeleteContextMenu(
                                            onDelete: deleteImage,
                                            padding: 0
                                        )
                                    }
                                }
                                .padding(8)
                            }
                        }
                }
            }
        }

        Rectangle()
            .fill(.clear)
            .frame(width: 0.1)
    }
}
