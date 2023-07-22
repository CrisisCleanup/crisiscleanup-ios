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

    var body: some View {
        let isBusy = viewModel.isLoading || viewModel.isSaving
        let disableMutation = viewModel.editableViewState.disabled

        ZStack {
            VStack {

                let tabTitles = viewModel.tabTitles

                HStack {
                    VStack {
                        HStack{
                            Spacer()
                            Text(tabTitles[.info] ?? "")
                                .onTapGesture {
                                    selectedTab = .info
                                }
                            Spacer()
                        }
                        Divider()
                            .frame(height: 2)
                            .background(selectedTab == .info ? Color.orange : Color.gray)
                    }
                    VStack {
                        HStack {
                            Spacer()
                            Text(tabTitles[.photos] ?? "")
                                .onTapGesture {
                                    selectedTab = .photos
                                }
                            Spacer()
                        }
                        Divider()
                            .frame(height: 2)
                            .background(selectedTab == .photos ? Color.orange : Color.gray)
                    }
                    VStack {
                        HStack{
                            Spacer()
                            Text(tabTitles[.notes] ?? "")
                                .onTapGesture {
                                    selectedTab = .notes
                                }
                            Spacer()
                        }
                        Divider()
                            .frame(height: 2)
                            .background(selectedTab == .notes ? Color.orange : Color.gray)
                    }
                }
                .padding(.top)

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
                .background(viewModel.alert ? Color.black : Color.clear)
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
                        .font(.headline)
                    Text(viewModel.subTitle)
                        .font(.subheadline)
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
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        HStack {
            VStack (alignment: .leading) {

                Text(t.t("caseForm.before_photos"))
                ScrollView(.horizontal, showsIndicators: false) {
                    MediaDisplay(category: .before)
                }

                Text(t.t("caseForm.after_photos"))
                ScrollView(.horizontal, showsIndicators: false) {
                    MediaDisplay(category: .after)
                }

            }
            .padding(.leading)
            Spacer()

        }

    }
}

private struct MediaDisplay: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel
    @Environment(\.translator) var t: KeyAssetTranslator

    var category: ImageCategory
    @State var photoDetents: Bool = false

    @State var results: [PhotosPickerItem] = []
    @State var testImages: [Image] = []
    @State var presentCamera: Bool = false
    @State var selectedImage: UIImage = UIImage()

    var body: some View {
        // TODO: Size relative to screen height
        let rowHeight = 160.0

        HStack {
            let r = appTheme.cornerRadius
            ZStack {
                let strokeColor = appTheme.colors.primaryBlueColor
                let cornerSize = CGSize(width: r, height: r)
                RoundedRectangle(cornerSize: cornerSize)
                    .fill(appTheme.colors.addMediaBackgroundColor)
                    .frame(width: 120, height: rowHeight)
                    .overlay {
                        RoundedRectangle(cornerSize: cornerSize)
                            .stroke(strokeColor, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    }

                // TODO: Common styles
                VStack {
                    Image(systemName: "plus")
                        .foregroundColor(strokeColor)
                    Text(t.t("actions.add_media"))
                        .foregroundColor(strokeColor)
                }
            }
            .padding(.all, r * 0.55)
            .onTapGesture {
                photoDetents.toggle()
            }
            .onChange(of: results) { _ in
                photoDetents = false
                Task {
                    for result in results {
                        // TODO: Save as a file.
                        if let data = try? await result.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                testImages.append(Image(uiImage: uiImage))

                            }
                        } else {
                            print("failed")
                        }
                    }

                    results = []
                }
            }

            ForEach(0..<testImages.count, id: \.self) { imageIndex in
                testImages[imageIndex]
                    .resizable()
                    .scaledToFit()
                    .frame(height: rowHeight)
                    .cornerRadius(appTheme.cornerRadius)
            }

            let beforeAfterImages = viewModel.beforeAfterPhotos[category] ?? []
            ForEach(beforeAfterImages, id: \.id) { caseImage in
                CachedAsyncImage(url: URL(string: caseImage.thumbnailUri)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: rowHeight)
                            .cornerRadius(appTheme.cornerRadius)
                            .onTapGesture {
                                router.viewImage(imageId: caseImage.id)
                            }
                    } else if phase.error != nil {
                        // TODO: Error view
                        Color.red // Indicates an error.
                    } else {
                        // TODO: Actual placeholder
                        Color.blue // Acts as a placeholder.
                    }
                }
            }
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
                        ImagePickerCamera(selectedImage: $selectedImage)
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
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    if(viewModel.caseData?.worksite.notes.hasSurvivorNote ?? false) {
                        HStack {
                            Spacer()
                            Image(systemName: "circle.fill")
                                .foregroundColor(appTheme.colors.survivorNoteColorNoTransparency)
                            Text(t.t("formLabels.survivor_notes"))
                        }
                        .padding()
                    }

                    if let notes = viewModel.caseData?.worksite.notes {
                        ForEach(notes, id: \.id) { note in
                            VStack(alignment: .leading) {
                                Text(note.createdAt.relativeTime)
                                    .font(.caption)
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(note.note)
                            }
                            .padding()
                            .background(note.isSurvivor ? appTheme.colors.survivorNoteColorNoTransparency : Color.white)
                            .cornerRadius(appTheme.cornerRadius)
                            .shadow(radius: appTheme.shadowRadius)
                            .padding(.horizontal)
                        }

                        // Spacing
                        Image("ic_note", bundle: .module)
                        // TODO: Common dimensions
                            .frame(width: 50, height: 50)
                            .padding()
                            .hidden()
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
                router.openCaseFlags()
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
                    Text(phoneText)
                    Spacer()
                }
                .modifier(CopyWithAnimation(pressed: $phonePressed, copy: phoneText))
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)

                if worksite.email?.isNotBlank == true {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .frame(width: iconSize, height: iconSize)
                        Text(worksite.email!)
                        Spacer()
                    }
                    .modifier(CopyWithAnimation(pressed: $emailPressed, copy: worksite.email!))
                    .horizontalVerticalPadding(horizontalPadding, verticalPadding)
                }

                let fullAddress = [
                    worksite.address,
                    worksite.city,
                    worksite.state,
                    worksite.postalCode,
                ].combineTrimText()
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .frame(width: iconSize, height: iconSize)
                    Text(fullAddress)
                    Spacer()
                }
                .modifier(CopyWithAnimation(pressed: $addressPressed, copy: fullAddress))
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)

                ViewCaseMapView(
                    map: $map,
                    caseCoordinates: CLLocationCoordinate2D(
                        latitude: worksite.latitude,
                        longitude: worksite.longitude
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
            }
            .cardContainerPadded()
        }
    }
}

struct CopyWithAnimation: ViewModifier {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var viewModel: ViewCaseViewModel
    @Binding var pressed: Bool
    var copy: String

    func body(content: Content) -> some View {
        content
            .background {
                Color.gray.opacity(pressed ? 0.5 : 0)
                    .animation(.easeInOut(duration: 0.25), value: pressed)
                    .cornerRadius(appTheme.cornerRadius)
            }
            .gesture(
                LongPressGesture()
                    .onEnded { _ in
                        pressed.toggle()
                        let message = t.t("info.copied_value").replacingOccurrences(of: "{copied_string}", with: copy)
                        viewModel.toggleAlert(message: message)
                        UIPasteboard.general.string = copy
                        let impactLight = UIImpactFeedbackGenerator(style: .light)
                        impactLight.impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            pressed.toggle()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.clearAlert()
                        }
                    }
            )
    }
}
