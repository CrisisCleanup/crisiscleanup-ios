//  Created by Anthony Aguilar on 7/6/23.

import SwiftUI
import MapKit
import FlowStackLayout

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
                    Group {
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
                    }
                    Divider()
                        .frame(height: 25)
                        .overlay(Color(UIColor.systemGray5))
                    Group {
                        Button {
                            sectionCollapse[1].toggle()
                        } label: {
                            HStack {
                                ViewCaseRowHeader(rowNum: 2, rowTitle: "t.tCase Details")
                                if(viewModel.detailsFormFieldNode.formField.help.isNotBlank) {
                                    HelpIcon(viewModel.detailsFormFieldNode.formField.help)
                                }
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
                    }

                    Divider()
                        .frame(height: 25)
                        .overlay(Color(UIColor.systemGray5))

                    Group {
                        Button {
                            sectionCollapse[2].toggle()
                        } label: {
                            HStack {
                                ViewCaseRowHeader(rowNum: 3, rowTitle: t.t("caseForm.work"))
                                if(viewModel.workFormFieldNode.formField.help.isNotBlank) {
                                    HelpIcon(viewModel.workFormFieldNode.formField.help)
                                }

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

                    }

                    Divider()
                        .frame(height: 25)
                        .overlay(Color(UIColor.systemGray5))

                    Group {
                        Button {
                            sectionCollapse[3].toggle()
                        } label : {
                            HStack {
                                ViewCaseRowHeader(rowNum: 4, rowTitle: "t.tHazards")

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
                    }

                    Divider()
                        .frame(height: 25)
                        .overlay(Color(UIColor.systemGray5))

                    Group {
                        Button {
                            sectionCollapse[4].toggle()
                        } label: {
                            HStack {
                                ViewCaseRowHeader(rowNum: 5, rowTitle: "t.tVolunteer Report")

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
    @Environment(\.translator) var t: KeyAssetTranslator
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
                        Text(t.t(option))
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
                Text("t.tCancel")
            }
            .buttonStyle(CancelButtonStyle())

            Button {

            } label : {
                Text("t.tClaim & Save")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {

            } label : {
                Text("t.tSave")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct PropertyInformation: View {
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CreateEditCaseViewModel
    @ObservedObject var locationManager = LocationManager()
    @State var coordinates = CLLocationCoordinate2D(latitude: 40.83834587046632,
                                longitude: 14.254053016537693)
    @State var map = MKMapView()
    @State var mapSheet = MKMapView()
    @State var selected: String = ""
    @State var selectedOptions: [String] = []
    @State var temp: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            VStack{
                TextField("t.tResident Name *", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)

                TextField("t.tPhone #s *", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)

                TextField("t.tPhone 2", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)

                TextField("t.tEmail", text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)
            }
            VStack(alignment: .leading) {
                Text("t.tAuto Contact Frequency")

                RadioPicker(selected: $selected, options: ["t.tOften (Twice a week)", "t.tNot Often (Once a week)", "t.tNever"])
                    .padding()
            }
            .padding(.leading)

            VStack(alignment: .leading) {
                Text(t.t("formLabels.location"))
                    .padding(.leading)

                TextField(
                    t.t("caseView.full_address"),
                    text: $temp,
                    onEditingChanged: { focus in
                        if focus {
                            router.openCaseSearchLocation()
                        }
                    }
                )
                .textFieldBorder()
                .padding(.horizontal)
            }

            CreateEditCaseMapView(
                map: $map,
                caseCoordinates: coordinates,
                toggled: false)
                .frame(width: UIScreen.main.bounds.width, height: 200)

            HStack {
                Button {
                    router.openCaseMoveOnMap()
                } label: {
                    Image(systemName: "map.fill")
                        .frame(width: 24, height: 24)
                    Text(t.t("caseForm.select_on_map"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    coordinates = map.userLocation.coordinate
                    map.centerCoordinate = coordinates
                } label: {
                    Image("ic_use_my_location", bundle: .module)
                        .frame(width: 24, height: 24)
                    Text(t.t("caseForm.use_my_location"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()

            TextField("Cross Street or Nearby Landmark", text: $temp)
                .textFieldBorder()
                .padding([.horizontal, .bottom])

            VStack(alignment: .leading) {

                CheckboxPicker(selectedOptions: $selectedOptions, options: ["t.tAddress Problems", "t.tFlag as high priority", "t.tMember of My Organization"])

            }
            .padding(.leading)

            VStack(alignment: .leading)
            {
                Text("t.tNotes")

                Button {
                    router.openCaseAddNote()
                } label : {
                    HStack {
                        Image("ic_note", bundle: .module)
                            .frame(width: 24, height: 24)
                        Text("+t.tAdd Note")
                    }
                }
            }
            .padding(.leading)

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
    @State var helpSheet: Bool = false

    var body: some View {

        VStack {
            switch node.formField.htmlType {
            case "text":
                HStack {
                    Text(t.t(node.formField.label))
                    if(node.formField.help.isNotBlank)
                    {
                        HelpIcon(node.formField.help)
                    }
                    Spacer()
                }
                TextField(t.t(node.formField.placeholder), text: $temp)
                    .textFieldBorder()
                    .padding(.horizontal)
            case "textarea":
                HStack {
                    Text(t.t(node.formField.label))
                    if(node.formField.help.isNotBlank)
                    {
                       HelpIcon(node.formField.help)
                    }
                    Spacer()
                }
                TextEditor(text: $temp)
                    .frame(minHeight: appTheme.rowItemHeight*2)
                    .textFieldBorder()
                    .padding(.horizontal)
            case "checkbox":
                HStack {
                    CheckboxPicker(selectedOptions: $selectedOptions, options: [node.formField.label])
                    if(node.formField.help.isNotBlank)
                    {
                        HelpIcon(node.formField.help)
                    }
                    Spacer()
                }
                .frame(minHeight: appTheme.rowItemHeight)
            case "select":
                HStack {
                    Text(t.t(node.formField.label))
                    if(node.formField.help.isNotBlank)
                    {
                        HelpIcon(node.formField.help)
                    }
                    Spacer()
                    Picker("", selection: $selected ) {
                        ForEach(Array(node.formField.values.keys), id: \.self) { item in
                            Text(t.t(item))
                        }
                    }
                }
                .frame(minHeight: appTheme.rowItemHeight)
            case "multiselect":
                HStack {
                    Text(t.t(node.formField.label))
                    if(node.formField.help.isNotBlank)
                    {
                        HelpIcon(node.formField.help)
                    }
                    Spacer()
                }
                FlowStack(
                    alignment: .leading,
                    horizontalSpacing: 8,
                    verticalSpacing: 8
                ) {
                    ForEach(Array(node.options.keys), id: \.self) { option in
                        Button {
                            if(selectedOptions.contains(option)) {
                                selectedOptions.remove(at: selectedOptions.firstIndex(of: option)!)
                            } else {
                                selectedOptions.append(option)
                            }
                        } label : {
                            Text(t.t(option))
                                .padding()
                                .background(selectedOptions.contains(option) ? Color.yellow : Color.white)
                                .cornerRadius(40)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(Color.black, lineWidth: selectedOptions.contains(option) ? 0 : 1)
                                )

                        }
                        .tint(.black)

                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([ .bottom])
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
                                if(node.formField.help.isNotBlank)
                                {
                                    HelpIcon(node.formField.help)
                                }
                                Spacer()
                                Image(systemName: toggled ? "chevron.up" : "chevron.down")
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
                            .frame(minHeight: appTheme.rowItemHeight, alignment: .leading)
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
