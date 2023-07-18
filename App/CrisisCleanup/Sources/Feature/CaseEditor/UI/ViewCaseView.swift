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
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(viewModel.headerTitle)
                                .font(.headline)
                            Text(viewModel.subTitle)
                                .font(.subheadline)
                        }
                        .onLongPressGesture {
                            UIPasteboard.general.string = viewModel.headerTitle
                        }
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
        }
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
                    HStack{
                        IncidentHeader(incident: caseState.incident)
                            .padding([.horizontal, .bottom])
                        Spacer()
                    }
                }

                if let worksiteFlag = viewModel.caseData?.worksite.flags {
                    FlowStack(
                        alignment: .leading,
                        horizontalSpacing: 8,
                        verticalSpacing: 8
                    ) {
                        ForEach(worksiteFlag, id: \.self) { flag in
                            WorksiteFlagChip(flag) {
                                viewModel.removeFlag(flag)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .bottom])
                }

                ViewCaseRowHeader(rowNum: 1, rowTitle: t.t("caseForm.property_information"))

                if let worksite = viewModel.caseData?.worksite {
                    PropertyInformationView(worksite: worksite)
                }

                if let workTypeProfile = viewModel.workTypeProfile {
                    InfoWorkView(profile: workTypeProfile)
                }
            }
        }
    }
}

private struct ViewCasePhotos: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel
    @Environment(\.translator) var t: KeyAssetTranslator

    @State var photoDetents: Bool = false
    @State var results: [PhotosPickerItem] = []
    @State var testImages: [Image] = []

    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                Text(t.t("caseForm.before_photos"))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerSize: CGSize(width: 2, height: 2))
                                .fill(Color.blue.opacity(0.5))
                                .frame(width: 200, height: 200)
                                .overlay {
                                    RoundedRectangle(cornerSize: CGSize(width: 2, height: 2))
                                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))

                                }

                            VStack {
                                Image(systemName: "plus")
                                    .foregroundColor(Color.blue)
                                Text("~~Add Media")
                                    .foregroundColor(Color.blue)
                            }
                        }
                        .onTapGesture {
                            photoDetents.toggle()
                        }
                        .onChange(of: results) { _ in
                            photoDetents = false
                            Task {
                                for result in results {
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
                                .frame(height: 200)
                                .cornerRadius(appTheme.cornerRadius)
                        }
                        Text(Array(viewModel.beforeAfterPhotos.keys).description)
                        Text(Array(viewModel.beforeAfterPhotos.values).description)
                        Text(viewModel.beforeAfterPhotos[.before]?.description ?? "none found")
                        let beforeImages = viewModel.beforeAfterPhotos[.before] ?? []
                        ForEach(beforeImages, id: \.id) { caseImage in
                            CachedAsyncImage(url: URL(string: caseImage.thumbnailUri))

                        }

                    }
                }

                Text(t.t("caseForm.after_photos"))
                ZStack {
                    RoundedRectangle(cornerSize: CGSize(width: 2, height: 2))
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 200, height: 200)
                        .overlay {
                            RoundedRectangle(cornerSize: CGSize(width: 2, height: 2))
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))

                        }

                    VStack {
                        Image(systemName: "plus")
                            .foregroundColor(Color.blue)
                        Text("~~Add Media")
                            .foregroundColor(Color.blue)
                    }
                }
                .onTapGesture {
                    photoDetents.toggle()
                }

                Button {
                    router.viewImage(imageId: 0)
                } label: {
                    Text("Photos")
                }
                Spacer()
            }
            .padding(.leading)
            Spacer()

        }
        .sheet(isPresented: $photoDetents) {
            ZStack {
                VStack {
                    Text(t.t("actions.take_photo"))
                        .padding()
                    PhotosPicker(selection: $results,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        Text(t.t("fileUpload.select_file_upload"))
                            .padding()
                    }

                }
            }
            .presentationDetents([.medium, .fraction(0.25)])
        }
    }
}

private struct ViewCaseNotes: View {
    @EnvironmentObject var router: NavigationRouter

    var body: some View {
        VStack {
            Button {
                router.openCaseAddNote()
            } label: {
                Text("Notes")
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
    let worksite: Worksite
    @State var map = MKMapView()

    var body: some View {
        VStack(alignment: .leading) {
            // TODO: Common dimensions
            let horizontalPadding = 8.0
            let verticalPadding = 4.0
            let iconSize = 36.0
            HStack {
                Image(systemName: "person.fill")
                    .frame(width: iconSize, height: iconSize)
                Text(worksite.name)


            }
            .onLongPressGesture {
                UIPasteboard.general.string = worksite.name
            }
            .horizontalVerticalPadding(horizontalPadding, verticalPadding)

            let phoneText = [worksite.phone1, worksite.phone2]
                .filter { $0?.isNotBlank == true }
                .joined(separator: "; ")
            HStack {
                Image(systemName: "phone.fill")
                    .frame(width: iconSize, height: iconSize)
                Text(phoneText)
            }
            .onLongPressGesture {
                UIPasteboard.general.string = phoneText
            }
            .horizontalVerticalPadding(horizontalPadding, verticalPadding)

            if worksite.email?.isNotBlank == true {
                HStack {
                    Image(systemName: "envelope.fill")
                        .frame(width: iconSize, height: iconSize)
                    Text(worksite.email!)
                }
                .onLongPressGesture {
                    UIPasteboard.general.string = worksite.email!
                }
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
            }
            .onLongPressGesture {
                UIPasteboard.general.string = fullAddress
            }
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
