//  Created by Anthony Aguilar on 6/30/23.

import SwiftUI
import MapKit

struct ViewCaseView: View {
    @Environment(\.isPresented) var isPresented

    @State var viewModel: ViewCaseViewModel
    var incident: Incident = Incident(id: 1234, name: "hurricane hello world", shortName: "short name", locationIds: [123], activePhoneNumbers: ["1234567890"], formFields: [], turnOnRelease: false, disasterLiteral: "temp")
    @State private var region = MKCoordinateRegion(
                   center: CLLocationCoordinate2D(
                       latitude: 40.83834587046632,
                       longitude: 14.254053016537693),
                   span: MKCoordinateSpan(
                       latitudeDelta: 0.03,
                       longitudeDelta: 0.03)
                   )
    @State private var offset = CGSize.zero

    enum ViewCaseTabs {
        case info
        case photos
        case notes
    }

    @State private var selectedTab: ViewCaseTabs = .info

    var body: some View {
        ZStack {
            VStack {

                HStack {
                    VStack {
                        HStack{
                            Spacer()
                            Text("Info")
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
                            Text("Photos")
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
                            Text("Notes")
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
                            Text("View Case#")
                                .font(.headline)
                            Text("county, state")
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
    @State var viewModel: ViewCaseViewModel
    @State var map = MKMapView()
    var incident: Incident = Incident(id: 1234, name: "hurricane hello world", shortName: "short name", locationIds: [123], activePhoneNumbers: ["1234567890"], formFields: [], turnOnRelease: false, disasterLiteral: "temp")
    @State private var region = MKCoordinateRegion(
                   center: CLLocationCoordinate2D(
                       latitude: 40.83834587046632,
                       longitude: 14.254053016537693),
                   span: MKCoordinateSpan(
                       latitudeDelta: 0.03,
                       longitudeDelta: 0.03)


                   )

    var body: some View {
        ScrollView {
            VStack {
                HStack{
                    IncidentHeader(incident: incident)
                        .padding([.leading, .bottom])
                    Spacer()
                }

                ViewCaseRowHeader(rowNum: 1, rowTitle: "Property Information")

                // create property information component?
                HStack {
                    VStack (alignment: .leading) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("First Name")
                        }
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("123-456-7890")
                        }
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("email@email.com")
                        }
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                            Text("12345 Main St. City, State 12345")
                        }

                    }
                    Spacer()
                }.padding()

                ViewCaseMapView(map: $map, caseCoordinates: CLLocationCoordinate2D(latitude: 40.83834587046632, longitude: 14.254053016537693))
                    .frame(width: UIScreen.main.bounds.size.width, height: 200)


                HStack {
                    ViewCaseRowHeader(rowNum: 3, rowTitle: "Work")

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

                ViewCaseRowHeader(rowNum: 5, rowTitle: "Volunteer Work")

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

private struct BottomNav: View {
    var body: some View {
        HStack {
            Spacer()

            VStack {
                Image("ic_case_share", bundle: .module)
                Text("Share")
            }
            Spacer()
            VStack {
                Image("ic_case_flag", bundle: .module)
                Text("Flag")
            }
            Spacer()
            VStack {
                Image("ic_case_history", bundle: .module)
                Text("History")
            }
            Spacer()
            VStack {
                Image("ic_case_edit", bundle: .module)
                Text("Edit")
            }
            Spacer()
        }
    }
}
