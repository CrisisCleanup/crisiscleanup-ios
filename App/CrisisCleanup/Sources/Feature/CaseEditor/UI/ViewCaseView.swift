//  Created by Anthony Aguilar on 6/30/23.

import SwiftUI
import MapKit

private let FlagColorFallback = Color(hex: 0xFF000000)
private let FlagColors = [
    WorksiteFlagType.highPriority: Color(hex: 0xFF367bc3),
    WorksiteFlagType.upsetClient: Color(hex: 0xFF00b3bf),
    WorksiteFlagType.reportAbuse: Color(hex: 0xFFd79425),
    WorksiteFlagType.wrongLocation: Color(hex: 0xFFf77020),
    WorksiteFlagType.wrongIncident: Color(hex: 0xFFc457e7),
]

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

                // TODO: Wrapping flag chips with delete actions

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
                            .padding([.leading, .bottom])
                        Spacer()
                    }
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
    var body: some View {
        Text("Photos")
    }
}

private struct ViewCaseNotes: View {
    var body: some View {
        VStack {
            Text("Notes")
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
            .horizontalVerticalPadding(horizontalPadding, verticalPadding)

            let phoneText = [worksite.phone1, worksite.phone2]
                .filter { $0?.isNotBlank == true }
                .joined(separator: "; ")
            HStack {
                Image(systemName: "phone.fill")
                    .frame(width: iconSize, height: iconSize)
                Text(phoneText)
            }
            .horizontalVerticalPadding(horizontalPadding, verticalPadding)

            if worksite.email?.isNotBlank == true {
                HStack {
                    Image(systemName: "envelope.fill")
                        .frame(width: iconSize, height: iconSize)
                    Text(worksite.email!)
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
