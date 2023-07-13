//  Created by Anthony Aguilar on 7/6/23.

import SwiftUI
import MapKit

struct CreateEditCaseView: View {
    @Environment(\.isPresented) var isPresented
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CreateEditCaseViewModel

    @State var sectionCollapse: [Bool] = [
        false,
        false,
        false,
        false,
        false
    ]
    var incident: Incident = Incident(id: 1, name: "temp", shortName: "temp", locationIds: [], activePhoneNumbers: [], formFields: [], turnOnRelease: true, disasterLiteral: "temp")

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    if let caseState = viewModel.caseData {
                        HStack{
                            IncidentHeader(incident: caseState.incident)
                                .padding([.horizontal, .bottom])
                            Spacer()
                        }
                    }

                    Button  {
                        sectionCollapse[0].toggle()
                    } label : {
                        HStack {
                            ViewCaseRowHeader(rowNum: 1, rowTitle: t.t("caseForm.property_information"))

                            Spacer()

                            Image(systemName: sectionCollapse[0] ? "chevron.up" : "chevron.down")
                            .padding(.trailing)
                        }
                        .tint(.black)
                    }

                    if(!sectionCollapse[0]) {
                        PropertyInformation(viewModel: viewModel)
                    }

                    Button {
                        sectionCollapse[1].toggle()
                    } label: {
                        HStack {
                            ViewCaseRowHeader(rowNum: 2, rowTitle: "Case Details")

                            Spacer()

                            Image(systemName: sectionCollapse[1] ? "chevron.up" : "chevron.down")
                            .padding(.trailing)
                        }
                    }
                    .tint(.black)
                    if(!sectionCollapse[1]) {
                        VStack {
                            let childNodes = viewModel.detailsFormFieldNode.children
                            ForEach(childNodes, id: \.id) { node in
                                if(node.parentKey == viewModel.detailsFormFieldNode.fieldKey)
                                {
                                    DisplayFormField(node: node)
                                        .padding(.horizontal)
                                }
                            }

                        }
                    }

                    Button {
                        sectionCollapse[2].toggle()
                    } label: {
                        HStack {
                            ViewCaseRowHeader(rowNum: 3, rowTitle: t.t("caseForm.work"))

                            Spacer()

                            Image(systemName: sectionCollapse[2] ? "chevron.up" : "chevron.down")
                            .padding(.trailing)
                        }
                    }
                    .tint(.black)

                    if(!sectionCollapse[2]) {
                        VStack {
                            let childNodes = viewModel.workFormFieldNode.children

                            ForEach(childNodes, id: \.id) { node in
//                                Text(node.children.debugDescription)
                                if(node.parentKey == viewModel.workFormFieldNode.fieldKey)
                                {
                                    HStack {
                                        DisplayFormField(node: node)
                                            .padding(.horizontal)
                                    }
                                }
                            }

                        }
                    }

                    Button {
                        sectionCollapse[3].toggle()
                    } label : {
                        HStack {
                            ViewCaseRowHeader(rowNum: 4, rowTitle: "Hazards")

                            Spacer()

                            Image(systemName: sectionCollapse[3] ? "chevron.up" : "chevron.down")
                            .padding(.trailing)
                        }
                    }
                    .tint(.black)
                    if(!sectionCollapse[3]) {
                        VStack {
                            let childNodes = viewModel.hazardsFormFieldNode.children
                            ForEach(childNodes, id: \.id) { node in
                                if(node.parentKey == viewModel.hazardsFormFieldNode.fieldKey) {
                                    DisplayFormField(node: node)
                                        .padding(.horizontal)
                                }
                            }

                        }
                    }
                    Group {
                        Button {
                            sectionCollapse[4].toggle()
                        } label: {
                            HStack {
                                ViewCaseRowHeader(rowNum: 5, rowTitle: "Volunteer Report")

                                Spacer()

                                Image(systemName: sectionCollapse[4] ? "chevron.up" : "chevron.down")
                                    .padding(.trailing)
                            }
                        }
                        .tint(.black)

                        if(!sectionCollapse[4]) {
                            VStack {
                                let childNodes = viewModel.volunteerFormFieldNode.children
                                ForEach(childNodes, id: \.id) { node in
                                    if(node.parentKey == viewModel.volunteerFormFieldNode.fieldKey) {
                                        DisplayFormField(node: node)
                                            .padding(.horizontal)
                                    }
                                }

                            }
                        }
                    }
                }
            }

            BottomButtons()

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
                    .padding(.bottom)
                }

            }
        }
    }
}

struct CheckboxPicker: View {
    @Environment(\.translator) var t: KeyAssetTranslator
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
                        Text(t.t(option))
                            .foregroundColor(Color.black)

                    }
                    .padding(.bottom)
                }

            }
        }
    }
}

struct BottomButtons: View {

    var body: some View {
        HStack {
            Button {

            } label : {
                Text("Cancel")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {

            } label : {
                Text("Claim & Save")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {

            } label : {
                Text("Save")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct PropertyInformation: View {
    @ObservedObject var viewModel: CreateEditCaseViewModel
    @ObservedObject var locationManager = LocationManager()
    @State var coordinates = CLLocationCoordinate2D(latitude: 40.83834587046632,
                                longitude: 14.254053016537693)
    @State var map = MKMapView()
    @State var mapSheet = MKMapView()
    @State var selected: String = ""
    @State var selectedOptions: [String] = []
    @State var temp: String = ""
    @State var selectOnMap = false

    var body: some View {
        VStack(alignment: .leading) {
            VStack{
                TextField("Resident Name *", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)

                TextField("Phone #s *", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)

                TextField("Phone 2", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)

                TextField("Email", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)
            }
            VStack(alignment: .leading) {
                Text("Auto Contact Frequency")

                RadioPicker(selected: $selected, options: ["Often (Twice a week)", "Not Often (Once a week)", "Never"])
                    .padding()
            }
            .padding(.leading)



            VStack(alignment: .leading) {
                Text("Location")
                    .padding(.leading)

                TextField("Location ", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)
            }

            CreateEditCaseMapView(map: $map, viewModel: viewModel, caseCoordinates: coordinates, toggled: false)
                .frame(width: UIScreen.main.bounds.width, height: 200)

            HStack {
                Spacer()
                Button {
                    selectOnMap.toggle()
                } label: {
                    Image(systemName: "map.fill")
                    Text("Select on Map")
                }
                .sheet(
                    isPresented: $selectOnMap
                ) {
//                                    CreateEditCaseMapView(map: $map, caseCoordinates: coordinates, toggled: true)
                    SelectOnMap(viewModel: viewModel, map: $mapSheet, caseCoordinates: $coordinates)
                }

                Spacer()

                Button {

                } label: {
                    Image(systemName: "location.circle")
                    Text("Use My Location")
                }

                Spacer()
            }
            .padding()

            TextField("Cross Street or Nearby Landmark", text: $temp)
                .textFieldBorder()
                .padding([.horizontal, .bottom])

            VStack(alignment: .leading) {

                CheckboxPicker(selectedOptions: $selectedOptions, options: ["Address Problems", "Flag as high priority", "Member of My Organization"])

            }
            .padding(.leading)

            VStack(alignment: .leading)
            {
                Text("Notes")

                Button {
                    // TODO: display noteUI
                } label : {
                    HStack {
                        Image(systemName: "note.text.badge.plus")
                        Text("+ Add Note")
                    }
                }
            }
            .padding(.leading)

        }
    }
}

struct SelectOnMap: View {
    @ObservedObject var viewModel: CreateEditCaseViewModel
    @Binding var map: MKMapView
    @Binding var caseCoordinates: CLLocationCoordinate2D
    @State var temp = ""

    var body: some View {
        VStack {
            TextField("Full address city, state, zip *", text: $temp)
                .textFieldBorder()
                .padding(.horizontal)

            CreateEditCaseMapView(map: $map, viewModel: viewModel, caseCoordinates: caseCoordinates, toggled: true)

            Button {
                map.showsUserLocation = true
                map.userTrackingMode
                map.centerCoordinate = map.userLocation.coordinate
            } label: {
                Image(systemName: "location.circle")
                Text("Use My Location")
            }

            Text(map.centerCoordinate.latLng.description)

            Text(caseCoordinates.latLng.description)

            HStack{

                Button {

                } label: {
                    Text("Cancel")
                }.buttonStyle(PrimaryButtonStyle())

                Button {
                    caseCoordinates = map.centerCoordinate

                } label: {
                    Text("Save")
                }.buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal)

        }
    }
}

struct DisplayFormField: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @State var node: FormFieldNode

    @State var selectedOptions: [String] = []
    @State var selected: String = ""
    @State var toggled: Bool = false
    @State var temp: String = ""

    var body: some View {

        VStack {
            switch node.formField.htmlType {
            case "text":
                HStack {
                    Text(t.t(node.formField.label))
                    Spacer()
                }
                TextField(t.t(node.formField.placeholder), text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)
            case "textarea":
                HStack {
                    Text(t.t(node.formField.label))
                    Spacer()
                }
                TextEditor(text: $temp)
                    .padding(.horizontal)
            case "checkbox":
                HStack {
                    CheckboxPicker(selectedOptions: $selectedOptions, options: [node.formField.label])
                    Spacer()
                }
            case "select":
                HStack {
                    Text(t.t(node.formField.label))
                    Spacer()
                    Picker("", selection: $selected ) {
                        ForEach(Array(node.formField.values.keys), id: \.self) { item in
                            Text(t.t(item))
                        }
                    }
                }
            case "multiselect":
                Text(t.t(node.formField.label))
            case "cronselect":
                Text(t.t(node.formField.label))
            case "h4":
                Text("h4")
                Text(t.t(node.formField.label))
            case "h5":
                HStack {

                    if(node.formField.isReadOnly) {
                        Button {
                            toggled.toggle()
                        } label : {
                            HStack {
                                Text(t.t(node.formField.label))
                                Spacer()
                            }
                        }
                    } else {
                        CheckboxPicker(selectedOptions: $selectedOptions, options: [t.t(node.formField.label)])
                    }
                    Spacer()
                }
                if(!selectedOptions.isEmpty && selectedOptions[0] == t.t(node.formField.label) || toggled){
                    let childNodes = node.children
                    ForEach(node.children, id: \.id) { childNode in
                        if(childNode.parentKey == node.fieldKey)
                        {
                            HStack {
                                DisplayFormField(node: childNode)
                                    .padding(.leading)
                            }
                        }
                    }
                }
            default:
                HStack {
                    Text("unknown node")
                    Text(t.t(node.formField.label))
                }
            }
        }
    }
}
