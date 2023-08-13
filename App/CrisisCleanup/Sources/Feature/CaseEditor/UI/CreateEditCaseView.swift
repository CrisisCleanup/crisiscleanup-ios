//  Created by Anthony Aguilar on 7/6/23.

import SwiftUI
import MapKit
import FlowStackLayout

struct CreateEditCaseView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var editableView: EditableView

    @ObservedObject var viewModel: CreateEditCaseViewModel

    @ObservedObject private var focusableViewState = TextInputFocusableView()

    @State var sectionCollapse = [
        false,
        false,
        false,
        false,
        false
    ]

    @State var sectionScrollCache = "section1"

    @State var isKeyboardOpen = false

    private let ignoreFormFieldKeys = Set(["cross_street", "email"])

    var body: some View {
        let disableMutation = viewModel.editableViewState.disabled
        let editSections = viewModel.editSections

        VStack {
            ScrollViewReader { proxy in
                FocusSectionSlider(
                    sectionTitles: editSections,
                    proxy: proxy
                )
                // TODO: Common dimensions
                .padding(.vertical, 8)

                ScrollView {
                    VStack {
                        if let caseState = viewModel.caseData {
                            HStack{
                                CaseIncidentView(
                                    incident: caseState.incident,
                                    isPendingSync: caseState.isPendingSync,
                                    isSyncing: viewModel.isSyncing,
                                    scheduleSync: { viewModel.scheduleSync() }
                                )
                                .padding()
                            }
                        }

                        Group {
                            CreateEditCaseSectionHeaderView (
                                isCollapsed: $sectionCollapse[0],
                                titleNumber: 1,
                                titleTranslateKey: editSections.get(0, "")
                            )
                            .id("section0")

                            if !sectionCollapse[0] {
                                PropertyInformation(viewModel: viewModel)
                            }
                        }
                        .onScrollSectionFocus(
                            proxy,
                            scrollToId: "scrollBar0"
                        )

                        let nodes = Array(viewModel.groupFormFieldNodes.enumerated())
                        ForEach(nodes, id: \.offset) { offset, node in
                            FormListSectionSeparator()

                            let sectionIndex = offset + 1
                            Group {
                                CreateEditCaseSectionHeaderView (
                                    isCollapsed: $sectionCollapse[sectionIndex],
                                    titleNumber: sectionIndex + 1,
                                    titleTranslateKey: editSections.get(sectionIndex, ""),
                                    helpText: node.formField.help
                                )
                                .id("section\(sectionIndex)")

                                VStack {
                                    if !sectionCollapse[sectionIndex] {
                                        let children = node.children
                                            .filter { !ignoreFormFieldKeys.contains($0.fieldKey) }
                                        ForEach(children, id: \.id) { child in
                                            if child.parentKey == node.fieldKey {
                                                DisplayFormField(
                                                    checkedData: $viewModel.binaryFormData,
                                                    contentData: $viewModel.contentFormData,
                                                    node: child
                                                )
                                                .padding(.horizontal)

                                            }
                                        }
                                    }
                                }
                            }
                            .onScrollSectionFocus(
                                proxy,
                                scrollToId: "scrollBar\(sectionIndex)"
                            )
                        }
                    }
                }
                .coordinateSpace(name: "scrollForm")
                .scrollDismissesKeyboard(.immediately)
            }

            if focusableViewState.isFocused {
                OpenKeyboardActionsView()
            } else {
                CreateEditCaseSaveActions()
                    .disabled(disableMutation)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.headerTitle)
            }
        }
        .hideNavBarUnderSpace()
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
        .environmentObject(viewModel.editableViewState)
        .environmentObject(focusableViewState)
    }
}

private func collapseIconName(_ isCollapsed: Bool) -> String {
    isCollapsed ? "chevron.up" : "chevron.down"
}

private struct CreateEditCaseSectionHeaderView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var isCollapsed: Bool

    let titleNumber: Int
    let titleTranslateKey: String
    var helpText = ""

    var body: some View {
        HStack {
            Button {
                isCollapsed.toggle()
            } label: {
                ViewCaseRowHeader(rowNum: titleNumber, rowTitle: t.t(titleTranslateKey))

                if helpText.isNotBlank {
                    HelpIcon(helpText)
                        .padding(.horizontal)
                }

                Spacer()

                Image(systemName: collapseIconName(isCollapsed))
            }
        }
        .padding()
        .tint(.black)
    }
}

struct PropertyInformation: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var editableView: EditableView
    @EnvironmentObject var locationManager: LocationManager

    @ObservedObject var viewModel: CreateEditCaseViewModel
    @State var coordinates = CLLocationCoordinate2D(
        latitude: 40.83834587046632,
        longitude: 14.254053016537693
    )
    @State var map = MKMapView()

    @State var residentName: String = ""
    @State var phone1: String = ""
    @State var phone2: String = ""
    @State var email: String = ""
    @State var autoContactFrequency: String = ""

    @State var fullAddressPlaceholder: String = ""
    @State var crossStreetLandmark: String = ""

    @State var activeFlags: [String] = []

    var body: some View {
        let disabled = editableView.disabled
        VStack(alignment: .leading) {
            VStack{
                TextField(t.t("formLabels.name"), text: $residentName)
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding([.horizontal, .bottom])

                TextField(t.t("formLabels.phone1"), text: $phone1)
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding([.horizontal, .bottom])

                TextField(t.t("formLabels.phone2"), text: $phone2)
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding([.horizontal, .bottom])

                TextField(t.t("formLabels.email"), text: $email)
                    .keyboardType(.emailAddress)
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding([.horizontal, .bottom])
            }
            VStack(alignment: .leading) {
                Text(t.t("casesVue.auto_contact_frequency"))

                RadioButtons(
                    selected: $autoContactFrequency,
                    options: autoContactFrequencyOptions.map { t.t($0.literal) }
                )
                .disabled(disabled)
                .padding()
            }
            .padding(.leading)

            VStack(alignment: .leading) {
                Text(t.t("formLabels.location"))
                    .padding(.leading)

                TextField(
                    t.t("caseView.full_address"),
                    text: $fullAddressPlaceholder,
                    onEditingChanged: { focus in
                        if focus {
                            router.openCaseSearchLocation()
                        }
                    }
                )
                .textFieldBorder()
                .disabled(disabled)
                .padding(.horizontal)
            }

            CreateEditCaseMapView(
                map: $map,
                caseCoordinates: coordinates)
            // TODO: Cap maximum height based on screen height (1/3?)
                .frame(width: UIScreen.main.bounds.width, height: 240)

            HStack {
                Button {
                    router.openCaseMoveOnMap()
                } label: {
                    Image(systemName: "map.fill")
                        .frame(width: 24, height: 24)
                    Text(t.t("caseForm.select_on_map"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(disabled)

                Button {
                    if locationManager.hasLocationAccess {
                        coordinates = map.userLocation.coordinate
                        map.centerCoordinate = coordinates
                    } else if locationManager.isDeniedLocationAccess {
                        // TODO: Show dialog to grant access from settings
                        print("Location access was previously denied")
                    } else {
                        locationManager.requestLocationAccess()
                    }
                } label: {
                    Image("ic_use_my_location", bundle: .module)
                        .frame(width: 24, height: 24)
                    Text(t.t("caseForm.use_my_location"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(disabled)
            }
            .padding()

            TextField(t.t("formLabels.cross_street"), text: $crossStreetLandmark)
                .textFieldBorder()
                .disabled(disabled)
                .padding([.horizontal, .bottom])

            VStack(alignment: .leading) {
                let flagOptions = viewModel.flagTranslateKeys
                CheckboxViews(
                    selectedOptions: $activeFlags,
                    options: flagOptions.map { ($0, t.t($0)) }
                )
            }
            .disabled(disabled)
            .padding(.leading)

            VStack(alignment: .leading)
            {
                Text(t.t("formLabels.notes"))

                Button {
                    router.openCaseAddNote()
                } label : {
                    HStack {
                        Image("ic_note", bundle: .module)
                            .frame(width: 24, height: 24)
                        Text(t.t("caseView.add_note"))
                    }
                }
                .disabled(disabled)
            }
            .padding(.leading)

        }
    }
}

struct DisplayFormField: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var editableView: EditableView

    @Binding var checkedData: ObservableBoolDictionary
    @Binding var contentData: ObservableStringDictionary

    let node: FormFieldNode

    var body: some View {
        let disabled = editableView.disabled

        VStack {
            switch node.formField.htmlType {
            case "text":
                HStack {
                    Text(t.t(node.formField.label))
                    if node.formField.help.isNotBlank
                    {
                        HelpIcon(node.formField.help)
                    }
                    Spacer()
                }
                TextField(t.t(node.formField.placeholder), text: $contentData[node.fieldKey])
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding(.bottom)
            case "textarea":
                HStack {
                    Text(t.t(node.formField.label))
                    if node.formField.help.isNotBlank {
                       HelpIcon(node.formField.help)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                TextEditor(text: $contentData[node.fieldKey])
                    .frame(minHeight: appTheme.rowItemHeight*2)
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding(.bottom)
            case "checkbox":
                HStack {
                    CheckboxView(
                        checked: $checkedData[node.fieldKey],
                        text: node.formField.label
                    )
                    .disabled(disabled)
                    if(node.formField.help.isNotBlank)
                    {
                        HelpIcon(node.formField.help)
                    }
                    Spacer()
                }
                .frame(minHeight: appTheme.rowItemHeight)
            case "select":
                HStack {
                    let label = t.t(node.formField.label)
                    Text(label)
                    if(node.formField.help.isNotBlank)
                    {
                        HelpIcon(node.formField.help)
                    }
                    Spacer()
                    let options = node.options
                    let sortedOptions = options
                        .map { $0 }
                        .sorted { a, b in
                            a.value.localizedCompare(b.value) == .orderedAscending
                        }
                    Picker("", selection: $contentData[node.fieldKey]) {
                        ForEach(sortedOptions, id: \.key) { (key, value) in
                            let text = t.t(options[key]!)
                            Text(text)
                        }
                    }
                    .disabled(disabled)
                }
                .frame(minHeight: appTheme.rowItemHeight)
            case "multiselect":
                HStack {
                    Text(t.t(node.formField.label))
                    if node.formField.help.isNotBlank {
                        HelpIcon(node.formField.help)
                    }
                }
                FlowStack(
                    alignment: .leading,
                    horizontalSpacing: 8,
                    verticalSpacing: 8
                ) {
                    // TODO: Test
                    let selectOptions = Array(contentData[node.fieldKey].split(separator: ","))
                        .map { String($0) }
                        .filter { $0.isNotBlank }
                    var selected = Set(selectOptions)
                    ForEach(Array(node.options.keys), id: \.self) { option in
                        let isSelected = selected.contains(option)
                        Button {
                            let newSelection = {
                                if isSelected {
                                    selected.remove(option)
                                } else {
                                    selected.insert(option)
                                }
                                return selected.joined(separator: ",")
                            }()
                            contentData[node.fieldKey] = newSelection
                        } label : {
                            Text(t.t(option))
                            // TODO: Common styles
                                .padding()
                                .background( isSelected ? Color.yellow : Color.white)
                                .cornerRadius(40)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(
                                            Color.black,
                                            lineWidth: isSelected ? 0 : 1
                                        )
                                )
                        }
                        .tint(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(disabled)
                .padding([.bottom])
            case "cronselect":
                Text(t.t(node.formField.label))
            case "h4":
                Text("h4")
                Text(t.t(node.formField.label))
            case "h5":
                let isChecked = checkedData[node.fieldKey]
                HStack {
                    if node.formField.isReadOnly {
                        Button {
                            checkedData[node.fieldKey] = !isChecked
                        } label : {
                            HStack {
                                Text(t.t(node.formField.label))
                                if node.formField.help.isNotBlank {
                                    HelpIcon(node.formField.help)
                                }
                                Spacer()
                                Image(systemName: collapseIconName(!isChecked))
                            }
                        }
                    } else {
                        CheckboxView(
                            checked: $checkedData[node.fieldKey],
                            text: t.t(node.formField.label)
                        )
                        .disabled(disabled)
                    }
                    Spacer()
                }
                if isChecked {
                    ForEach(node.children, id: \.id) { childNode in
                        HStack {
                            DisplayFormField(
                                checkedData: $checkedData,
                                contentData: $contentData,
                                node: childNode
                            )
                            .padding(.leading)
                        }
                        .frame(minHeight: appTheme.rowItemHeight, alignment: .leading)
                    }
                }
            default:
                HStack {
                    Text(t.t(node.formField.label))
                }
            }
        }
    }
}

private struct CreateEditCaseSaveActions: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var editableView: EditableView

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label : {
                Text(t.t("actions.cancel"))
            }
            .styleCancel()

            Button {
                // TODO: Do
            } label : {
                Text(t.t("actions.save_claim"))
            }
            .stylePrimary()
            .frame(maxWidth: .infinity)

            Button {
                // TODO: Do
            } label : {
                Text(t.t("actions.save"))
            }
            .stylePrimary()
        }
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
