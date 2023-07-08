//  Created by Anthony Aguilar on 6/30/23.

import SwiftUI
import MapKit

struct ViewCaseView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.isPresented) var isPresented

    @ObservedObject var viewModel: ViewCaseViewModel

    @State private var offset = CGSize.zero

    @State private var selectedTab: ViewCaseTabs = .info

    var body: some View {
        ZStack {
            VStack {

                // TODO: Flag chips with delete actions

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
                            Image(systemName: "exclamationmark.triangle.fill")

                            Image(systemName: "heart.fill")
                        }

                    }
                }

                // TODO: redraws the view when switching tabs? Change Zindex instead?
                switch selectedTab {
                case .info:
                    ViewCaseInfo(viewModel: viewModel)
                case .photos:
                    ViewCasePhotos()
                case .notes:
                    ViewCaseNotes()
                }

                Spacer()

                BottomNav()

            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct ViewCaseInfo: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: ViewCaseViewModel

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

                ViewCaseRowHeader(rowNum: 1, rowTitle: t("caseForm.property_information"))

                if let worksite = viewModel.caseData?.worksite {
                    PropertyInformationView(worksite: worksite)
                }

                HStack {
                    ViewCaseRowHeader(rowNum: 3, rowTitle: t("caseForm.work"))

                    VStack (alignment: .trailing) {
                        // TODO: make component
                        Text("Claim all available work types")
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.5)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(appTheme.cornerRadius)
                        Text("Release all")
                            .lineLimit(1)
                            .padding()
                            .background(Color.white)
                            .border(.black, width: 2)
                            .cornerRadius(appTheme.cornerRadius)
                    }.padding(.trailing)

                }

                VStack {
                    Text("Claimed by")
                        .padding(.horizontal)
                    Text("Cocoa Florida Stake, The Church of Jesus Christ of Latter Day Saints")
                        .padding(.horizontal)

                    WorkTypeRow()
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

    private let imageName: String
    private let textTranslateKey: String

    init(
        _ imageName: String,
        _ textTranslateKey: String
    ) {
        self.imageName = imageName
        self.textTranslateKey = textTranslateKey
    }

    var body: some View {
        Button {
            // TODO: Router action
        } label: {
            VStack {
                Image(imageName, bundle: .module)
                Text(t(textTranslateKey))
            }
        }
    }
}

private struct BottomNav: View {
    @EnvironmentObject var router: NavigationRouter

    var body: some View {
        // TODO: Space evenly within safe area rather than Spacers on ends
        HStack {
            Spacer()
            Button {
                router.openCaseShare()
            } label: {
                BottomNavButton("ic_case_share", "actions.share")
            }
            Spacer()
            Button {
                router.openCaseFlags()
            } label: {
                BottomNavButton("ic_case_flag", "nav.flag")
            }
            Spacer()
            Button {
                router.openCaseHistory()
            } label: {
                BottomNavButton("ic_case_history", "actions.history")
            }
            Spacer()
            Button {

            } label: {
                BottomNavButton("ic_case_edit", "actions.edit")
            }
            Spacer()
        }
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
        .background(.white)
        .cornerRadius(appTheme.cornerRadius)
        .padding()
        .shadow(radius: appTheme.shadowRadius)
    }
}
