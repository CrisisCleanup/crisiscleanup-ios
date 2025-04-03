//  Created by Anthony Aguilar on 7/6/23.

import Combine
import FlowStackLayout
import MapKit
import SwiftUI

struct CreateEditCaseView: View {
    @ObservedObject var viewModel: CreateEditCaseViewModel

    var body: some View {
        CreateEditCaseLayoutView()
            .environmentObject(viewModel)
    }
}

private struct CreateEditCaseLayoutView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewLayout: ViewLayoutDescription
    @EnvironmentObject var viewModel: CreateEditCaseViewModel

    @ObservedObject private var focusableViewState = TextInputFocusableView()

    @State private var showBusyIndicator = true

    private let referenceScrollSpace = "scrollFrom"

    var body: some View {
        ZStack {
            if viewModel.editSections.isNotEmpty {
                if viewLayout.isListDetailLayout {
                    GeometryReader { proxy in
                        HStack {
                            CreateEditCaseSaveActions(isVertical: true)
                                .frame(width: proxy.size.width * listDetailListFractionalWidth)

                            CreateEditCaseContentView(
                                isCompactLayout: viewLayout.isShort,
                                isSaveBarVisible: false
                            )
                            .frame(width: proxy.size.width * listDetailDetailFractionalWidth)
                            .coordinateSpace(name: referenceScrollSpace)
                        }
                    }
                    .frame(maxWidth: appTheme.wideContentMaxWidth, alignment: .center)
                } else {
                    CreateEditCaseContentView(
                        isCompactLayout: viewLayout.isShort,
                        isSaveBarVisible: true
                    )
                    .coordinateSpace(name: referenceScrollSpace)
                    .frame(maxWidth: appTheme.contentMaxWidth, alignment: .center)
                }
            }

            if showBusyIndicator {
                ProgressView()
            }

            if viewModel.showExplainLocationPermission {
                LocationAppSettingsDialog {
                    viewModel.showExplainLocationPermission = false
                }
            }
        }
        .screenTitle(viewModel.headerTitle)
        .hideNavBarUnderSpace()
        .onChange(of: viewModel.areEditorsReady) { isReady in
            withAnimation {
                showBusyIndicator = !isReady
            }
        }
        .onChange(of: viewModel.navigateBack) { b in
            if b {
                dismiss()
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environment(\.translator, viewModel)
        .environmentObject(viewModel.editableViewState)
        .environmentObject(focusableViewState)
        .onChange(of: viewModel.changeWorksiteIncidentId) { newValue in
            if newValue != EmptyIncident.id {
                router.changeCaseIncident(newValue)
            }
        }
        .onChange(of: viewModel.changeExistingWorksite.isDefined) { newValue in
            router.changeCaseIncident(viewModel.changeExistingWorksite)
        }
    }
}

private struct CreateEditCaseContentView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CreateEditCaseViewModel
    @EnvironmentObject private var focusableViewState: TextInputFocusableView

    private var isCompactLayout = false
    private var isSaveBarVisible = false

    @State private var isInvalidSave = false

    private let contentScrollChangeSubject = CurrentValueSubject<(String, CGFloat), Never>(("", 0.0))
    private let contentScrollStopDelay: AnyPublisher<String, Never>

    @State private var sectionCollapse = [
        false,
        false,
        false,
        false,
        false,
        false
    ]

    @State private var arePhotoOptionsOpen = false

    init(
        isCompactLayout: Bool,
        isSaveBarVisible: Bool
    ) {
        self.isCompactLayout = isCompactLayout
        self.isSaveBarVisible = isSaveBarVisible

        contentScrollStopDelay = contentScrollChangeSubject
            .debounce(for: .seconds(0.2), scheduler: RunLoop.current)
            .map { $0.0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var body: some View {
        let disableMutation = viewModel.editableViewState.disabled
        let editSections = viewModel.editSections

        ScrollViewReader { proxy in
            FocusSectionSlider(
                sectionTitles: editSections,
                proxy: proxy,
                onScrollToSection: { index in
                    if index >= 0 && index < sectionCollapse.count {
                        sectionCollapse[index] = false
                    }
                }
            )
            .padding(.vertical, appTheme.gridItemSpacing)

            ScrollView {
                VStack {
                    if let caseState = viewModel.caseData {
                        CaseIncidentView(
                            incident: caseState.incident,
                            isPendingSync: caseState.isPendingSync,
                            isSyncing: viewModel.isSyncing,
                            scheduleSync: { viewModel.scheduleSync() }
                        )
                        .padding()
                    }

                    VStack {
                        CreateEditCaseScrollingSections(
                            sectionCollapse: $sectionCollapse,
                            arePhotoOptionsOpen: $arePhotoOptionsOpen,
                            isCompactLayout: isCompactLayout,
                            proxy: proxy,
                            editSections: editSections,
                            contentScrollChangeSubject: contentScrollChangeSubject
                        )
                        .onReceive(contentScrollStopDelay) { scrollToId in
                            if scrollToId.isNotBlank {
                                withAnimation {
                                    proxy.scrollTo(scrollToId, anchor: .leading)
                                }
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: focusableViewState.focusState) { focusState in
                let isNameFocus = focusState == .caseInfoName
                if isNameFocus {
                    withAnimation {
                        proxy.scrollTo("property-name-input", anchor: .top)
                    }
                }
            }
            .onChange(of: viewModel.locationInputData.wasGeocodeAddressSelected) { isSelected in
                if isSelected {
                    withAnimation {
                        proxy.scrollTo("location-map", anchor: .top)
                    }
                }
            }
            .onChange(of: viewModel.locationInputData.isLocationAddressFound) { isFound in
                if isFound {
                    withAnimation {
                        proxy.scrollTo("location-map", anchor: .top)
                    }
                }
            }
            .onChange(of: viewModel.invalidWorksiteInfo) { info in
                isInvalidSave = info.invalidElement != .none || info.message.isNotBlank
            }
            // TODO: What is causing the scroll view to change when the photo options sheet is closed?
            .onChange(of: arePhotoOptionsOpen) { newValue in
                if !newValue {
                    proxy.scrollTo("section-photos", anchor: .top)
                }
            }
            .sheet(isPresented: $isInvalidSave) {
                let info = viewModel.invalidWorksiteInfo
                let message = info.message.ifBlank {
                    t.t("caseForm.missing_required_fields")
                }
                VStack {
                    Text(message)
                        .padding()

                    Spacer()

                    if info.invalidElement != .none {
                        Button(t.t("actions.fix")) {
                            let scrollId = info.invalidElement.scrollId
                            if scrollId.isNotBlank {
                                proxy.scrollTo(scrollId, anchor: .top)
                            }

                            isInvalidSave = false
                        }
                    }
                }
                // TODO: Adjust to content height (remove Spacer)
                .presentationDetents([.fraction(0.35)])
            }

            if isSaveBarVisible {
                if focusableViewState.isFocused {
                    OpenKeyboardActionsView()
                } else {
                    CreateEditCaseSaveActions(isVertical: false)
                        .disabled(disableMutation)
                }
            }
        }
    }
}

private struct CreateEditCaseScrollingSections: View {
    @EnvironmentObject var viewModel: CreateEditCaseViewModel

    @Binding var sectionCollapse: Array<Bool>
    @Binding var arePhotoOptionsOpen: Bool

    var isCompactLayout = false

    let proxy: ScrollViewProxy
    let editSections: [String]
    let contentScrollChangeSubject: any Subject<(String, CGFloat), Never>

    var body: some View {
        VStack {
            CreateEditCaseSectionHeaderView(
                isCollapsed: $sectionCollapse[0],
                titleNumber: 1,
                titleTranslateKey: editSections.get(0, "")
            )
            .id("section0")

            if !sectionCollapse[0] {
                PropertyInformation(
                    propertyData: viewModel.propertyInputData,
                    locationData: viewModel.locationInputData
                )
            }
        }
        .onScrollSectionFocus(
            proxy,
            scrollToId: "scrollBar0",
            scrollChangeSubject: contentScrollChangeSubject
        )

        let nodes = Array(viewModel.groupFormFieldNodes.enumerated())
        ForEach(nodes, id: \.offset) { offset, node in
            FormListSectionSeparator()

            let sectionIndex = offset + 1
            VStack {
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
                        ForEach(children, id: \.viewId) { child in
                            if child.parentKey == node.fieldKey {
                                DisplayFormField(
                                    checkedData: $viewModel.binaryFormData,
                                    contentData: $viewModel.contentFormData,
                                    workTypeStatuses: $viewModel.statusOptions,
                                    statusData: $viewModel.workTypeStatusFormData,
                                    isNewCase: viewModel.isCreateWorksite,
                                    node: child,
                                    isWorkTypeClaimed: viewModel.isWorkTypeClaimed
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .onScrollSectionFocus(
                proxy,
                scrollToId: "scrollBar\(sectionIndex)",
                scrollChangeSubject: contentScrollChangeSubject
            )
        }

        let lastIndex = editSections.count - 1
        VStack {
            CreateEditCaseSectionHeaderView (
                isCollapsed: $sectionCollapse[lastIndex],
                titleNumber: lastIndex + 1,
                titleTranslateKey: editSections.get(lastIndex, "")
            )
            .id("section\(lastIndex)")
            .id("section-photos")

            if !sectionCollapse[lastIndex] {
                CasePhotosView(
                    arePhotoOptionsOpen: _arePhotoOptionsOpen,
                    isCompactLayout: isCompactLayout
                )
            }
        }
        .onScrollSectionFocus(
            proxy,
            scrollToId: "scrollBar\(lastIndex)",
            scrollChangeSubject: contentScrollChangeSubject
        )
    }
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
                    let translatedHelp: String = {
                        let translateKey = "formLabels.\(helpText)"
                        var translated = t.t(translateKey)
                        if translated == translateKey {
                            translated = t.t(helpText)
                        }
                        return translated
                    }()
                    HelpIcon(translatedHelp)
                        .padding(.horizontal)
                }

                Spacer()

                CollapsibleIcon(isCollapsed: isCollapsed)
            }
        }
        .padding()
        .tint(.black)
    }
}

private struct ErrorTextView: View {
    let text: String
    var paddingEdges: Edge.Set = []

    var body: some View {
        if text.isNotBlank {
            Text(text)
                .fontHeader3()
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(appTheme.colors.primaryRedColor)
                .padding(paddingEdges)
        }
    }
}

private struct PropertyInformation: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: CreateEditCaseViewModel
    @EnvironmentObject var editableView: EditableView
    @EnvironmentObject var focusableViewState: TextInputFocusableView
    @EnvironmentObject var locationManager: LocationManager

    @ObservedObject var propertyData: PropertyInputData
    @ObservedObject var locationData: LocationInputData

    @FocusState private var focusState: TextInputFocused?

    @State private var map = MKMapView()

    @State private var fullAddressPlaceholder: String = ""

    @State private var showNameResults = false

    var body: some View {
        let disabled = editableView.disabled
        VStack(alignment: .leading) {
            Group {
                ErrorTextView(text: propertyData.residentNameError)
                    .id("property-name-error")
                TextField(t.t("formLabels.name"), text: $propertyData.residentName)
                    .textInputAutocapitalization(.words)
                    .focused($focusState, equals: .caseInfoName)
                    .onSubmit {
                        focusState = .caseInfoPhone
                    }
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding(.bottom)
                    .id("property-name-input")

                if showNameResults {
                    Text(t.t("actions.stop_searching_cases"))
                        .fontHeader3()
                        .listItemModifier()
                        .onTapGesture {
                            viewModel.stopSearchingName()
                        }

                    ForEach(viewModel.nameSearchResults.worksites, id: \.id) { worksite in
                        CaseView(worksite: worksite)
                            .onTapGesture {
                                viewModel.onExistingWorksiteSelected(worksite)
                            }
                            .padding()
                    }
                }

                ErrorTextView(text: propertyData.phoneNumberError)
                    .id("property-phone-error")
                TextField(t.t("formLabels.phone1"), text: $propertyData.phoneNumber)
                    .focused($focusState, equals: .caseInfoPhone)
                    .onSubmit {
                        focusState = .caseInfoPhone2
                    }
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding(.bottom)

                TextField(t.t("formLabels.phone2"), text: $propertyData.phoneNumberSecondary)
                    .focused($focusState, equals: .caseInfoPhone2)
                    .onSubmit {
                        focusState = .caseInfoEmail
                    }
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding(.bottom)

                ErrorTextView(text: propertyData.emailError)
                    .id("property-email-error")
                TextField(t.t("formLabels.email"), text: $propertyData.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusState, equals: .caseInfoEmail)
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding(.bottom)
            }
            .padding(.horizontal)
            .onChange(of: viewModel.hasNameResults) { newValue in
                withAnimation {
                    showNameResults = newValue
                }
            }
            .onChange(of: viewModel.editIncidentWorksite) { identifier in
                if identifier != ExistingWorksiteIdentifierNone {
                    router.viewCase(
                        incidentId: identifier.incidentId,
                        worksiteId: identifier.worksiteId,
                        popToRoot: true
                    )
                }
            }
            .onChange(of: viewModel.invalidWorksiteInfo) { info in
                let focusElement = info.invalidElement.focusElement
                let clearFocus = info.invalidElement == .work || focusElement == .anyTextInput
                focusState = clearFocus ? nil : focusElement
            }

            VStack(alignment: .leading) {
                HStack {
                    Text(t.t("casesVue.auto_contact_frequency"))
                    HelpIcon(t.t("casesVue.auto_contact_frequency_help"))
                }
                .listItemModifier()

                ForEach(autoContactFrequencyOptions, id: \.self) { option in
                    RadioButton(
                        text: t.t(option.literal),
                        isSelected: option == propertyData.autoContactFrequency,
                        nestedLevel: 1,
                        isListItem: true
                    ) {
                        propertyData.autoContactFrequency = option
                    }
                }
                .disabled(disabled)
            }

            HStack {
                Text(t.t("formLabels.location"))
                    .id("location-section")
                HelpIcon(t.t("caseForm.location_instructions"))
            }
            .listItemModifier()

            if viewModel.isOnline && locationData.isSearchSuggested {
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

            let outOfBoundsMessage = viewModel.locationOutOfBoundsMessage
            CreateEditCaseMapView(
                map: $map,
                latLng: $locationData.coordinates,
                isCreateWorksite: viewModel.isCreateWorksite,
                hasInitialCoordinates: viewModel.hasInitialCoordinates
            )
            .id("location-map")
            .if (viewModel.areEditorsReady && outOfBoundsMessage.isNotBlank) { view in
                view.overlay(alignment: .bottomLeading) {
                    Text(outOfBoundsMessage)
                        .fontBodySmall()
                        .padding()
                        .background(.white.disabledAlpha())
                        .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: appTheme.listItemMapHeight)

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
                    viewModel.useMyLocation()
                } label: {
                    Image("ic_use_my_location", bundle: .module)
                        .frame(width: 24, height: 24)
                    Text(t.t("caseForm.use_my_location"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(disabled)
            }
            .padding()

            CaseAddressFormFields(
                locationData: locationData,
                focusState: $focusState
            )

            TextField(t.t("formLabels.cross_street"), text: $locationData.crossStreetNearbyLandmark)
                .focused($focusState, equals: .caseInfoCrossStreet)
                .textFieldBorder()
                .disabled(disabled)
                .padding([.horizontal, .bottom])

            VStack(alignment: .leading) {
                ForEach(viewModel.flagTranslateKeys, id: \.self) { key in
                    let isSelected: Bool = {
                        switch (key) {
                        case highPriorityLabelKey:
                            return viewModel.isHighPriority
                        case wrongLocationLabelKey:
                            return locationData.hasWrongLocation
                        case orgMemberLabelKey:
                            return viewModel.isAssignedToOrgMember
                        default:
                            return false
                        }
                    }()
                    Button {
                        let toggleSelected = !isSelected
                        switch (key) {
                        case highPriorityLabelKey:
                            viewModel.isHighPriority = toggleSelected
                        case wrongLocationLabelKey:
                            locationData.hasWrongLocation = toggleSelected
                        case orgMemberLabelKey:
                            viewModel.isAssignedToOrgMember = toggleSelected
                        default:
                            print("Flag \(key) does not update any state")
                        }
                    } label: {
                        let label = t.t(key)
                        CheckboxTextView(isChecked: isSelected, text: label)
                    }
                    .listItemModifier()
                }
            }
            .disabled(disabled)

            CreateEditCaseNotesView()
        }
        .onChange(of: focusState) {
            focusableViewState.focusState = $0
            showNameResults = false
        }
        .onDisappear {
            focusState = nil
        }
    }
}

private struct CaseAddressFormFields: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CreateEditCaseViewModel
    @EnvironmentObject var editableView: EditableView
    @EnvironmentObject private var focusableViewState: TextInputFocusableView

    @ObservedObject var locationData: LocationInputData

    @FocusState.Binding var focusState: TextInputFocused?

    var body: some View {
        let disabled = editableView.disabled

        if locationData.isEditingAddress ||
            locationData.hasWrongLocation ||
            locationData.streetAddressError.isNotBlank ||
            locationData.cityError.isNotBlank ||
            locationData.countyError.isNotBlank ||
            locationData.stateError.isNotBlank ||
            locationData.zipCodeError.isNotBlank {

            Group {
                Group {
                    ErrorTextView(text: locationData.streetAddressError)
                        .id("location-address-error")
                    TextField(t.t("formLabels.address"), text: $locationData.streetAddress)
                        .focused($focusState, equals: .caseInfoStreetAddress)
                        .onSubmit {
                            focusState = .caseInfoCity
                        }
                        .textFieldBorder()
                        .padding(.bottom)

                    ErrorTextView(text: locationData.cityError)
                        .id("location-city-error")
                    TextField(t.t("formLabels.city"), text: $locationData.city)
                        .onSubmit {
                            focusState = .caseInfoCounty
                        }
                        .focused($focusState, equals: .caseInfoCity)
                        .textFieldBorder()
                        .padding(.bottom)
                }

                Group {
                    ErrorTextView(text: locationData.countyError)
                        .id("location-county-error")
                    TextField(t.t("formLabels.county"), text: $locationData.county)
                        .focused($focusState, equals: .caseInfoCounty)
                        .onSubmit {
                            focusState = .caseInfoState
                        }
                        .textFieldBorder()
                        .padding(.bottom)

                    ErrorTextView(text: locationData.stateError)
                        .id("location-state-error")
                    TextField(t.t("formLabels.state"), text: $locationData.state)
                        .focused($focusState, equals: .caseInfoState)
                        .onSubmit {
                            focusState = .caseInfoZipCode
                        }
                        .textFieldBorder()
                        .padding(.bottom)

                    ErrorTextView(text: locationData.zipCodeError)
                        .id("location-zip-code-error")
                    TextField(t.t("formLabels.postal_code"), text: $locationData.zipCode)
                        .focused($focusState, equals: .caseInfoZipCode)
                        .onSubmit {
                            // TODO: Parent should receive this signal
                            focusState = .caseInfoCrossStreet
                        }
                        .textFieldBorder()
                        .padding(.bottom)
                }
            }
            .disabled(disabled)
            .padding(.horizontal)
            .onChange(of: viewModel.invalidWorksiteInfo) { info in
                let focusElement = info.invalidElement.focusElement
                let clearFocus = info.invalidElement == .work || focusElement == .anyTextInput
                focusState = clearFocus ? nil : focusElement
            }

        } else {
            let addressSummary = locationData.addressSummary
            if addressSummary.isNotEmpty {
                ZStack(alignment: .bottomTrailing) {
                    let addressText = addressSummary.joined(separator: "\n")
                    Text(addressText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()

                    HStack(spacing: appTheme.gridItemSpacing) {
                        Button {
                            locationData.clearAddress()
                        } label: {
                            Image(systemName: "trash.fill")
                                .frame(width: 24, height: 24)
                        }
                        Button {
                            locationData.isEditingAddress = true
                        } label: {
                            Image(systemName: "pencil")
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding()
                }
                .roundedBorder()
                .disabled(disabled)
                .padding()
            }
        }
    }
}

private struct CreateEditCaseNotesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: CreateEditCaseViewModel
    @EnvironmentObject var editableView: EditableView

    @State private var showAllNotes = false

    var body: some View {
        let disabled = editableView.disabled

        VStack(alignment: .leading)
        {
            let notes = viewModel.worksiteNotes

            HStack {
                Text(t.t("formLabels.notes"))
                    .id("section-notes")

                if notes.count > viewModel.visibleNoteCount {
                    Spacer()

                    Button {
                        showAllNotes = true
                    } label: {
                        Text(t.t("actions.all_notes"))
                    }

                }
            }
            .listItemModifier()

            if notes.hasSurvivorNote == true {
                SurvivorNoteLegend()
                    .listItemPadding()
            }

            let noteCount = min(notes.count, viewModel.visibleNoteCount)
            StaticNotesList(notes: Array(notes[0..<noteCount]))

            LargeTextEditor(
                text: $viewModel.editingNote,
                placeholder: t.t("caseView.note")
            )
            .id("note-input")
            .listItemModifier()
            .disabled(disabled)

            Button(t.t("actions.add")) {
                let note = WorksiteNote.create().copy {
                    $0.note = viewModel.editingNote
                }
                viewModel.saveNote(note)
                viewModel.editingNote = ""
            }
            .stylePrimary()
            .padding(.horizontal)
            .disabled(viewModel.editingNote.isBlank || disabled)
        }
        .sheet(isPresented: $showAllNotes) {
            let notes = viewModel.worksiteNotes
            if notes.hasSurvivorNote {
                SurvivorNoteLegend()
                    .padding()
            } else {
                Rectangle()
                    .fill(.clear)
                    .background(.clear)
                    .frame(height: 8)
            }
            ScrollLazyVGrid {
                StaticNotesList(
                    notes: notes,
                    otherNotes: viewModel.otherNotes
                )
            }
        }
        .presentationDetents([.large])
    }
}

private struct DisplayFormFieldLabel: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let node: FormFieldNode

    var body: some View {
        Text(node.formField.translatedLabel(t))
        if node.formField.help.isNotBlank {
            let helpTranslateKey = "formLabels.\(node.formField.help)"
            let helpText: String = {
                let translated = t.t(helpTranslateKey)
                return translated == helpTranslateKey ? t.t(node.formField.help) : translated
            }()
            HelpIcon(helpText)
        }
    }
}

struct DisplayFormField: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var editableView: EditableView
    @EnvironmentObject var focusableViewState: TextInputFocusableView

    @Binding var checkedData: BindingBoolDictionary
    @Binding var contentData: BindingStringDictionary
    @Binding var workTypeStatuses: [WorkTypeStatus]
    @Binding var statusData: BindingStringDictionary

    @State private var multiSelected: Set<String> = []

    let isNewCase: Bool

    let node: FormFieldNode

    let isWorkTypeClaimed: (String) -> Bool

    @FocusState private var focusState: TextInputFocused?

    var body: some View {
        let disabled = editableView.disabled

        VStack {
            switch node.formField.htmlType {
            case "text":
                HStack {
                    DisplayFormFieldLabel(node: node)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                TextField(t.t(node.formField.placeholder), text: $contentData[node.fieldKey])
                    .focused($focusState, equals: .anyTextInput)
                    .textFieldBorder()
                    .disabled(disabled)
                    .padding(.bottom)

            case "textarea":
                HStack {
                    DisplayFormFieldLabel(node: node)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                LargeTextEditor(text: $contentData[node.fieldKey])
                    .disabled(disabled)
                    .padding(.bottom)

            case "checkbox":
                HStack {
                    CheckboxView(
                        checked: $checkedData[node.fieldKey],
                        text: node.formField.translatedLabel(t)
                    )
                    .disabled(disabled)
                    if node.formField.help.isNotBlank {
                        HelpIcon(node.formField.help)
                    }
                    Spacer()
                }
                .frame(minHeight: appTheme.rowItemHeight)

            case "select":
                HStack {
                    DisplayFormFieldLabel(node: node)
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
                    DisplayFormFieldLabel(node: node)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                FlowStack(
                    alignment: .leading,
                    horizontalSpacing: appTheme.gridActionSpacing,
                    verticalSpacing: appTheme.gridActionSpacing
                ) {
                    let selectionString = contentData[node.fieldKey]
                    var selected = { () -> Set<String> in
                        var set = multiSelected
                        if set.isEmpty {
                            let selectOptions = Array(selectionString.split(separator: ","))
                                .map { String($0) }
                                .filter { $0.isNotBlank }
                            set = Set(selectOptions)
                        }
                        return set
                    }()
                    ForEach(Array(node.options.keys), id: \.self) { option in
                        let isSelected = selected.contains(option)
                        Button {
                            if isSelected {
                                selected.remove(option)
                            } else {
                                selected.insert(option)
                            }
                            contentData[node.fieldKey] = selected.joined(separator: ",")
                            multiSelected = selected
                        } label : {
                            Text(t.t(option))
                                .styleMultiSelectChip(isSelected)
                        }
                        .tint(.black)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(disabled)
                .padding([.bottom])

            case "cronselect":
                FrequencySelectView(
                    checkedData: $checkedData,
                    rruleString: $contentData[node.fieldKey],
                    node: node
                )
                .disabled(disabled)

            case "h4", "h5":
                let isChecked = checkedData[node.fieldKey]
                HStack {
                    if node.children.isEmpty && node.formField.isReadOnly {
                        Text(node.formField.translatedLabel(t))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, appTheme.listItemVerticalPadding)
                    } else {
                        CheckboxView(
                            checked: $checkedData[node.fieldKey],
                            text: node.formField.translatedLabel(t)
                        )
                        .disabled(disabled)

                        let isActiveWorkType = isChecked && node.isWorkTypeGroup
                        if !isNewCase && isActiveWorkType {
                            Spacer()

                            let workTypeLiteral = node.formField.selectToggleWorkType
                            let selectedStatusLiteral = statusData[workTypeLiteral]
                            let selectedStatus = statusFromLiteral(selectedStatusLiteral, .openUnassigned)
                            WorkTypeStatusPicker(
                                selectedStatus: selectedStatus,
                                isClaimed: isWorkTypeClaimed(node.formField.selectToggleWorkType),
                                statusOptions: workTypeStatuses,
                                spanWidth: false
                            ) {
                                focusState = nil
                            } onSelectStatus: { status in
                                statusData[workTypeLiteral] = status.literal
                            }
                        } else if node.formField.help.isNotBlank {
                            HelpIcon(node.formField.help)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isChecked {
                    ForEach(node.children, id: \.viewId) { childNode in
                        HStack {
                            DisplayFormField(
                                checkedData: $checkedData,
                                contentData: $contentData,
                                workTypeStatuses: $workTypeStatuses,
                                statusData: $statusData,
                                isNewCase: isNewCase,
                                node: childNode,
                                isWorkTypeClaimed: isWorkTypeClaimed
                            )
                            .padding(.leading)
                        }
                        .frame(minHeight: appTheme.rowItemHeight, alignment: .leading)
                    }
                }
            default:
                HStack {
                    Text(node.formField.translatedLabel(t))
                }
            }
        }
        .onChange(of: focusState) { focusableViewState.focusState = $0 }
    }
}

private struct CasePhotosView: View {
    @EnvironmentObject var viewModel: CreateEditCaseViewModel

    @Binding var arePhotoOptionsOpen: Bool

    var isCompactLayout: Bool = false

    var body: some View {
        ViewCasePhotosView(
            caseMediaManager: viewModel.caseMediaManager,
            headerTitle: viewModel.headerTitle,
            isCompactLayout: isCompactLayout,
            areOptionsOpen: _arePhotoOptionsOpen
        )
    }
}

private struct SaveActions: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var viewModel: CreateEditCaseViewModel

    var body: some View {
        Button(t.t("actions.cancel")) {
            dismiss()
        }
        .styleCancel()

        Button(t.t("actions.save")) {
            viewModel.saveChanges(false)
        }
        .stylePrimary()

        Button(t.t("actions.save_claim")) {
            viewModel.saveChanges(true)
        }
        .stylePrimary()
    }
}

private struct CreateEditCaseSaveActions: View {
    var isVertical = false

    var body: some View {
        if isVertical {
            VStack(spacing: appTheme.gridActionSpacing) {
                Spacer()

                SaveActions()
            }
            .padding([.horizontal, .bottom], appTheme.edgeSpacing)
        } else {
            HStack {
                SaveActions()
            }
            .padding([.horizontal, .bottom], appTheme.gridItemSpacing)
        }
    }
}
