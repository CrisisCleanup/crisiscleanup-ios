//  Created by Anthony Aguilar on 7/6/23.

import SwiftUI
import MapKit

struct CreateEditCaseView: View {
    @Environment(\.isPresented) var isPresented
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CreateEditCaseViewModel

    var coordinates = CLLocation(latitude: 20, longitude: 20)

    @State var map = MKMapView()
    @State var selected: String = ""
    @State var selectedOptions: [String] = []
    @State var temp: String = ""

    var incident: Incident = Incident(id: 1, name: "temp", shortName: "temp", locationIds: [], activePhoneNumbers: [], formFields: [], turnOnRelease: true, disasterLiteral: "temp")

    var body: some View {
        VStack {
            ScrollView {
                VStack {
//                    if let caseState = viewModel.caseData {
                        HStack{
//                            IncidentHeader(incident: caseState.incident)
                            IncidentHeader(incident: incident)
                                .padding([.leading, .bottom])
                            Spacer()
                        }
//                    }

                    HStack {
                        ViewCaseRowHeader(rowNum: 1, rowTitle: t.t("caseForm.property_information"))

                        // TODO: add dropdown
                    }

                    VStack(alignment: .leading) {
                        VStack{
                            TextField("Resident Name *", text: $temp)
                                .padding(.horizontal)
                                .textFieldStyle(.roundedBorder)

                            TextField("Phone #s *", text: $temp)
                                .padding(.horizontal)
                                .textFieldStyle(.roundedBorder)

                            TextField("Phone 2", text: $temp)
                                .padding(.horizontal)
                                .textFieldStyle(.roundedBorder)

                            TextField("Email", text: $temp)
                                .padding(.horizontal)
                                .textFieldStyle(.roundedBorder)
                        }

                        // TODO: Make radio buttons

                        VStack(alignment: .leading) {
                            Text("Auto Contact Frequency")

                            RadioPicker(selected: $selected, options: ["Often (Twice a week)", "Not Often (Once a week)", "Never"])
                        }
                        .padding(.leading)



                        VStack(alignment: .leading) {
                            Text("Location")
                                .padding(.leading)

                            TextField("Location ", text: $temp)
                                .padding(.horizontal)
                                .textFieldStyle(.roundedBorder)
                        }



                        ViewCaseMapView(map: $map, caseCoordinates: CLLocationCoordinate2D(latitude: 20, longitude: 20))
                            .frame(width: UIScreen.main.bounds.width, height: 200)

                        VStack(alignment: .leading) {
                            HStack {
                                Spacer()
                                Image(systemName: "map.fill")
                                Text("Select on Map")

                                Image(systemName: "location.circle")
                                Text("Use My Location")
                                Spacer()
                            }

                            CheckboxPicker(selectedOptions: $selectedOptions, options: ["Address Problems", "Flag as high priority", "Member of My Organization"])

                        }
                        .padding(.leading)

                        VStack(alignment: .leading)
                        {
                            Text("Notes")

                            HStack {
                                Image(systemName: "note.text.badge.plus")
                                Text("+ Add Note")
                            }
                        }
                        .padding(.leading)

                    }

                    HStack {
                        ViewCaseRowHeader(rowNum: 2, rowTitle: "Case Details")

                        // TODO: add dropdown
                    }

                    HStack {
                        ViewCaseRowHeader(rowNum: 3, rowTitle: t.t("caseForm.work"))

                        // TODO: add dropdown
                    }

                    HStack {
                        ViewCaseRowHeader(rowNum: 4, rowTitle: "Hazards")

                        // TODO: add dropdown
                    }

                    HStack {
                        ViewCaseRowHeader(rowNum: 5, rowTitle: "Volunteer Report")

                        // TODO: add dropdown
                    }
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .environmentObject(viewModel.editableViewState)
    }
}

struct RadioPicker: View {
    @Binding var selected: String
    var options: [String]

    var body: some View {
        VStack (alignment: .leading){

            ForEach(options, id: \.self) {option in
                Button {
                    selected = option
                } label: {
                    HStack{
                        let ifSelected = option == selected
                        let radioImg = ifSelected ? "circle.fill" : "circle"
                        Image(systemName: radioImg)
                            .foregroundColor(ifSelected ? Color.black : Color.gray)
                        Text(option)
                            .foregroundColor(Color.black)

                    }
                }

            }
        }
    }
}

struct CheckboxPicker: View {
    @Binding var selectedOptions: [String]
    var options: [String]

    var body: some View {
        VStack (alignment: .leading){

            ForEach(options, id: \.self) {option in
                Button {
                    if(selectedOptions.contains(option))
                    {
                        selectedOptions.remove(at: selectedOptions.firstIndex(of: option)!)
                    } else {
                        selectedOptions.append(option)
                    }
                } label: {
                    HStack{
                        let ifSelected = selectedOptions.contains(option)
                        let radioImg = ifSelected ? "checkmark.square.fill" : "square"
                        Image(systemName: radioImg)
                            .foregroundColor(ifSelected ? Color.black : Color.gray)
                        Text(option)
                            .foregroundColor(Color.black)

                    }
                }

            }
        }
    }
}
