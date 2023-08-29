//  Created by Anthony Aguilar on 6/30/23.

import FlowStackLayout
import MapKit
import SwiftUI
import PhotosUI
import CachedAsyncImage

struct ViewCaseView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: ViewCaseViewModel

    @State private var selectedTab: ViewCaseTabs = .info
    @State private var titlePressed: Bool = false

    private let infoTabs = Array([
        ViewCaseTabs.info,
        ViewCaseTabs.photos,
        ViewCaseTabs.notes
    ].enumerated())

    var body: some View {
        let isBusy = viewModel.isLoading || viewModel.isSaving
        let disableMutation = viewModel.editableViewState.disabled

        ZStack {
            VStack {
                let updatedAt = viewModel.updatedAtText
                if updatedAt.isNotBlank {
                    Text(updatedAt)
                        .fontBodySmall()
                        .listItemModifier()
                }

                HStack {
                    let tabTitles = viewModel.tabTitles
                    ForEach(infoTabs, id: \.offset) { (index, tab) in
                        VStack {
                            HStack{
                                Spacer()
                                Text(tabTitles[tab] ?? "")
                                    .fontHeader4()
                                    .onTapGesture {
                                        selectedTab = tab
                                    }
                                Spacer()
                            }
                            Divider()
                                .frame(height: 2)
                                .background(selectedTab == tab ? Color.orange : Color.gray)
                        }
                    }
                }

                // TODO: redraws the view when switching tabs? Change Zindex instead?
                switch selectedTab {
                case .info:
                    ViewCaseInfo()
                case .photos:
                    ViewCasePhotos()
                case .notes:
                    ViewCaseNotes()
                }

                Spacer()

                BottomNav()
            }

            if isBusy {
                VStack {
                    ProgressView()
                        .frame(alignment: .center)
                }
            }

            VStack {
                HStack {
                    Text(viewModel.alertMessage)
                        .foregroundColor(Color.white)
                        .padding()
                }
                .background(viewModel.alert ? appTheme.colors.navigationContainerColor : Color.clear)
                .cornerRadius(appTheme.cornerRadius)
                .animation(.easeInOut(duration: 0.25), value: viewModel.alert)
                Spacer()
            }
            .padding(.top)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(viewModel.headerTitle)
                        .fontHeader3()
                    Text(viewModel.subTitle)
                        .fontBodySmall()
                }
                .modifier(CopyWithAnimation(pressed: $titlePressed, copy: viewModel.headerTitle))
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        viewModel.toggleHighPriority()
                    } label: {
                        let tint = getTopIconActionColor(viewModel.referenceWorksite.hasHighPriorityFlag)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .tint(tint)
                    }
                    .disabled(disableMutation)

                    Button {
                        viewModel.toggleFavorite()
                    } label: {
                        let isFavorite = viewModel.referenceWorksite.isLocalFavorite
                        let tint = getTopIconActionColor(isFavorite)
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .tint(tint)
                    }
                    .disabled(disableMutation)
                }
            }
        }
        .hideNavBarUnderSpace()
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .environmentObject(viewModel.editableViewState)
        .onReceive(viewModel.$isPendingTransfer) { isPendingTransfer in
            let isTransferStarted = isPendingTransfer && viewModel.transferType != .none
            if isTransferStarted {
                router.openWorkTypeTransfer()
            }
        }
    }

    private func getTopIconActionColor(_ isActive: Bool) -> Color {
        isActive ? appTheme.colors.primaryRedColor : appTheme.colors.neutralIconColor
    }
}

private struct ViewCaseInfo: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var body: some View {
        ScrollView {
            VStack {
                if let caseState = viewModel.caseData {
                    CaseIncidentView(
                        incident: caseState.incident,
                        isPendingSync: caseState.isPendingSync,
                        isSyncing: viewModel.isSyncing,
                        scheduleSync: {
                            viewModel.scheduleSync()
                        }
                    )
                    .padding()

                    if let worksiteFlags = caseState.worksite.flags,
                       worksiteFlags.isNotEmpty {
                        FlowStack(
                            alignment: .leading,
                            horizontalSpacing: 8,
                            verticalSpacing: 8
                        ) {
                            ForEach(worksiteFlags, id: \.self) { flag in
                                WorksiteFlagChip(flag) {
                                    viewModel.removeFlag(flag)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .bottom])
                    }

                    ViewCaseRowHeader(rowNum: 1, rowTitle: t.t("caseForm.property_information"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    PropertyInformationView(worksite: caseState.worksite)

                    if let workTypeProfile = viewModel.workTypeProfile {
                        InfoWorkView(profile: workTypeProfile)
                    }
                }
            }
        }
    }
}

private struct ViewCasePhotos: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var body: some View {
        VStack (alignment: .leading) {
            ViewCasePhotosSection(category: .before)
            ViewCasePhotosSection(category: .after)
            Spacer()
        }
    }
}

private struct ViewCasePhotosSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let category: ImageCategory

    var body: some View {
        let sectionTranslateKey = category == .before
        ? "caseForm.before_photos"
        : "caseForm.after_photos"
        Text(t.t(sectionTranslateKey))
            .fontHeader4()
            .padding([.horizontal, .top])
        ScrollView(.horizontal, showsIndicators: false) {
            MediaDisplay(category: category)
        }
    }
}

private struct MediaDisplay: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var category: ImageCategory
    @State var photoDetents: Bool = false

    @State var results: [PhotosPickerItem] = []
    @State var mediaImages: [Image] = []
    @State var presentCamera: Bool = false
    @State var takePhotoImage: UIImage = UIImage()

    // TODO: Size relative to remaining screen height
    let oneRowHeight = 172.0

    func openViewImage(_ caseImage: CaseImage) {
        router.viewImage(
            caseImage.id,
            caseImage.isNetworkImage,
            viewModel.headerTitle
        )
    }

    var body: some View {
        let beforeAfterImages = viewModel.beforeAfterPhotos[category] ?? []
        let rowHeight = oneRowHeight
        let rowActionHeight = rowHeight - 12
        let iconFont = Font.system(size: rowHeight * 0.8)
        HStack {
            Rectangle()
                .fill(.clear)
                .frame(width: 0.1, height: rowHeight)

            let r = appTheme.cornerRadius
            ZStack {
                let strokeColor = appTheme.colors.primaryBlueColor
                let cornerSize = CGSize(width: r, height: r)
                RoundedRectangle(cornerSize: cornerSize)
                    .fill(appTheme.colors.addMediaBackgroundColor)
                    .frame(width: 120, height: rowActionHeight)
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
            .padding(.all, r * 0.55)
            .onTapGesture {
                viewModel.addImageCategory = category
                photoDetents.toggle()
            }
            .onChange(of: results) { _ in
                photoDetents = false
                viewModel.onMediaSelected(results)
                results = []
            }

            ForEach(0..<viewModel.cachingLocalImageCount[category.literal], id: \.self) { index in
                Image(systemName: "photo")
                    .foregroundColor(appTheme.colors.addMediaBackgroundColor)
                    .font(iconFont)
            }

            ForEach(beforeAfterImages, id: \.id) { caseImage in
                if caseImage.isNetworkImage {
                    CachedAsyncImage(url: URL(string: caseImage.thumbnailUri)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: rowHeight)
                                .cornerRadius(appTheme.cornerRadius)
                                .onTapGesture { openViewImage(caseImage) }
                        } else if phase.error != nil {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(appTheme.colors.primaryRedColor)
                                .font(iconFont)
                        } else {
                            Image(systemName: "photo.circle")
                                .foregroundColor(.gray)
                                .font(iconFont)
                        }
                    }
                } else {
                    if let image = viewModel.localImageCache[caseImage.imageUri] {
                        let isSyncing = viewModel.syncingWorksiteImage == caseImage.id
                        let alignment: Alignment = isSyncing ? .center : .topTrailing
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: rowHeight)
                            .cornerRadius(appTheme.cornerRadius)
                            .onTapGesture { openViewImage(caseImage) }
                            .overlay(alignment: alignment) {
                                if isSyncing {
                                    Image(systemName: "cloud.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 48, height: 48)
                                        .padding()
                                        .background(.white.opacity(0.8))
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "cloud.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                        .padding(4)
                                        .background(.white.opacity(0.5))
                                        .clipShape(Circle())
                                        .padding(8)
                                }
                            }
                    }
                }
            }

            Rectangle()
                .fill(.clear)
                .frame(width: 0.1, height: rowHeight)
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
                            viewModel.onPhotoTaken(newValue)
                            takePhotoImage = UIImage()
                            photoDetents = false
                        }
                    }

                    PhotosPicker(selection: $results,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        Text(t.t("fileUpload.select_file_upload"))
                            .padding()
                    }
                    .tint(.black)

                }
            }
            .presentationDetents([.medium, .fraction(0.25)])
        }
    }
}

private struct ViewCaseNotes: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    if viewModel.caseData?.worksite.notes.hasSurvivorNote == true {
                        SurvivorNoteLegend()
                            .padding()
                    } else {
                        Rectangle()
                            .fill(.clear)
                            .background(.clear)
                            .frame(height: 8.0)
                    }

                    if let notes = viewModel.caseData?.worksite.notes {
                        ForEach(notes, id: \.id) { note in
                            VStack(alignment: .leading) {
                                Text(note.createdAt.relativeTime)
                                    .font(.caption)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                // TODO: Render HTML (no links)
                                Text(note.note)
                            }
                            .padding()
                            .cardContainer(background: note.isSurvivor ? appTheme.colors.survivorNoteColorNoTransparency : Color.white)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }

                        // Spacing
                        Rectangle()
                            .fill(.clear)
                            .background(.clear)
                        // TODO: Common dimensions
                            .frame(height: 50.0)
                            .padding(.vertical)
}
                }
                .padding(.bottom)
            }

            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button {
                        router.openCaseAddNote()
                    } label: {
                        Image("ic_note", bundle: .module)
                        // TODO: Common dimensions
                            .frame(width: 50, height: 50)
                            .background(appTheme.colors.attentionBackgroundColor)
                            .tint(.black)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                            .padding()

                    }

                }
            }
        }
    }
}

private struct BottomNavButton: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var editableView: EditableView

    private let action: () -> Void
    private let imageName: String
    private let textTranslateKey: String

    init(
        _ imageName: String,
        _ textTranslateKey: String,
        _ action: @escaping () -> Void
    ) {
        self.imageName = imageName
        self.textTranslateKey = textTranslateKey
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            VStack {
                Image(imageName, bundle: .module)
                Text(t.t(textTranslateKey))
                    .fontBodySmall()
            }
        }
        .disabled(editableView.disabled)
    }
}

private struct BottomNav: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var body: some View {
        HStack {
            BottomNavButton("ic_case_share", "actions.share")
            {
                router.openCaseShare()
            }
            Spacer()
            BottomNavButton("ic_case_flag", "nav.flag") {
                router.openCaseFlags(isFromCaseEdit: true)
            }
            Spacer()
            BottomNavButton("ic_case_history", "actions.history") {
                router.openCaseHistory()
            }
            Spacer()
            BottomNavButton("ic_case_edit", "actions.edit") {
                router.createEditCase(
                    incidentId: viewModel.incidentIdIn,
                    worksiteId: viewModel.worksiteIdIn
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top)
        .tint(.black)
    }
}

private struct PropertyInformationView: View {
    @EnvironmentObject var viewModel: ViewCaseViewModel
    let worksite: Worksite
    @State private var namePressed: Bool = false
    @State private var phonePressed: Bool = false
    @State private var emailPressed: Bool = false
    @State private var addressPressed: Bool = false
    @State var map = MKMapView()

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                // TODO: Common dimensions
                let horizontalPadding = 8.0
                let verticalPadding = 4.0
                let iconSize = 36.0
                HStack {
                    Image(systemName: "person.fill")
                        .frame(width: iconSize, height: iconSize)
                    Text(worksite.name)
                    Spacer()

                }
                .modifier(CopyWithAnimation(pressed: $namePressed, copy: worksite.name))
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)

                let phoneText = [worksite.phone1, worksite.phone2]
                    .filter { $0?.isNotBlank == true }
                    .joined(separator: "; ")
                HStack {
                    Image(systemName: "phone.fill")
                        .frame(width: iconSize, height: iconSize)

                    // TODO: Custom link won't work with the two numbers combined into one text
                    Text(phoneText)
                        .customLink(urlString: "tel:\(phoneText)")

                    Spacer()
                }
                .modifier(CopyWithAnimation(pressed: $phonePressed, copy: phoneText))
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)

                if worksite.email?.isNotBlank == true {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .frame(width: iconSize, height: iconSize)
                        Text(worksite.email!)
                            .customLink(urlString: worksite.email!)
                        Spacer()
                    }
                    .modifier(CopyWithAnimation(pressed: $emailPressed, copy: worksite.email!))
                    .horizontalVerticalPadding(horizontalPadding, verticalPadding)
                }

                let (addressText, addressMapItem) = worksite.addressQuery
                HStack {
                    Image(systemName: "mappin")
                        .frame(width: iconSize, height: iconSize)

                    Button {
                        // TODO: Alert if wrong location flag was set
                        addressMapItem.openInMaps()
                    } label : {
                        Text(addressText)
                            .underline()
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()
                }
                .modifier(CopyWithAnimation(pressed: $addressPressed, copy: addressText))
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)

                ViewCaseMapView(
                    map: $map,
                    caseCoordinates: CLLocationCoordinate2D(
                        latitude: worksite.latitude,
                        longitude: worksite.longitude
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: appTheme.listItemMapHeight)
            }
            .cardContainerPadded()
        }
    }
}
