import SwiftUI

struct CaseFlagsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseFlagsViewModel

    @State var selected: WorksiteFlagType? = nil

    private let keyboardVisibilityProvider = KeyboardVisibilityProvider()

    var body: some View {
        VStack {
            HStack {
                Text(t.t("events.object_flag"))

                let options = viewModel.flagFlows
                Picker("", selection: $selected) {
                    if selected == nil {
                        Text(t.t("flag.choose_problem")).tag(Optional<WorksiteFlagType>(nil))
                    }
                    ForEach(options, id: \.self) { option in
                        Text(t.t(option.literal)).tag(Optional(option))
                    }
                }

                // TODO: Animate visibility
                if viewModel.isSaving {
                    ProgressView()
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)

            let isEditable = viewModel.isEditable

            switch selected {
            case .some (let unwrapped):
                switch unwrapped {
                case WorksiteFlagType.highPriority:
                    HighPriority()

                case WorksiteFlagType.upsetClient:
                    UpsetClient()

                case WorksiteFlagType.markForDeletion:
                    Spacer()
                    AddFlagSaveActionBar {
                        viewModel.onAddFlag(.markForDeletion)
                    }

                case WorksiteFlagType.reportAbuse:
                    ReportAbuse()

                case WorksiteFlagType.duplicate:
                    Spacer()
                    AddFlagSaveActionBar {
                        viewModel.onAddFlag(.duplicate)
                    }

                case WorksiteFlagType.wrongLocation:
                    WrongLocation(isEditable: isEditable)

                case WorksiteFlagType.wrongIncident:
                    WrongIncident(isEditable: isEditable)
                }
            default:
                Spacer()
            }
        }
        .onReceive(viewModel.$isSaved) { isSaved in
            if isSaved {
                dismiss()
            }
        }
        .onReceive(keyboardPublisher) { isVisible in
            keyboardVisibilityProvider.isKeyboardVisible = isVisible
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(t.t("nav.flag"))
            }
        }
        .environmentObject(viewModel)
        .environmentObject(keyboardVisibilityProvider)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

struct ContactSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    var org: IncidentOrganization

    var body: some View {
        VStack(alignment: .leading) {
            Text(org.name)
                .font(.title)
                .padding(.top)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(t.t("flag.primary_contacts"))
                .font(.title2)
                .padding(.bottom)

            ForEach(org.primaryContacts, id: \.id) { contact in
                Text(contact.fullName)
                    .bold()
                    .padding(.bottom, 4)

                if contact.email.isNotBlank,
                   let emailUri = URL(string: "mailto:\(contact.email)") {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Link(contact.email, destination: emailUri)
                    }
                    .padding(.bottom, 4)
                }

                if contact.mobile.isNotBlank,
                   let phoneUri = URL(string: "tel:\(contact.mobile)") {
                    HStack {
                        Image(systemName: "phone.fill")
                        Link(contact.mobile, destination: phoneUri)
                    }
                    .padding(.bottom, 8)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

private struct HighPriority: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel
    @State var showContactSheet: Bool = false

    @State var isHighPriority: Bool = false
    @State var flagDescription = ""
    @State var selectedOrg = EmptyIncidentOrganization

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                CheckboxView(
                    checked: $isHighPriority,
                    text: t.t("flag.flag_high_priority")
                )

                Text(t.t("flag.please_describe_why_high_priority"))
                LargeTextEditor(text: $flagDescription)
                    .padding(.bottom)

                if let nearbyOrganizations = viewModel.nearbyOrganizations {
                    if nearbyOrganizations.isNotEmpty {
                        Text(t.t("flag.nearby_organizations"))
                            .bold()
                            .padding(.bottom, 4)

                        Text(t.t("caseHistory.do_not_share_contact_warning"))
                            .bold()
                            .padding(.bottom, 4)

                        Text(t.t("caseHistory.do_not_share_contact_explanation"))
                            .padding(.bottom)

                        Group {
                            ForEach(nearbyOrganizations, id:\.id) { org in
                                Button {
                                    selectedOrg = org
                                } label : {
                                    Text(t.t(org.name))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical)
                            }
                        }
                        .onChange(of: selectedOrg, perform: { org in
                            if org.id != EmptyIncident.id {
                                showContactSheet = true
                            }
                        })
                        .sheet(isPresented: $showContactSheet) {
                            ContactSheet(org: selectedOrg)
                                .presentationDetents([.medium, .large])
                        }
                    }
                }
                else {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)

        Spacer()

        AddFlagSaveActionBar(
            observeKeyboard: true
        ) {
            viewModel.onHighPriority(isHighPriority, flagDescription)
        }
    }
}

private func getBoolOptional(
    _ s: String,
    yesOption: String,
    noOption: String
) -> Bool? {
    s == yesOption ? true : (s == noOption ? false : nil)
}

private struct UpsetClient: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    @State var upsetReason = ""
    @State var isMyOrgInvolved = ""
    @State var selectedOrg: OrganizationIdName? = nil

    @FocusState private var isQueryFocused: Bool
    @State private var animateTopSearchBar = false
    var tempOrgs = ["org1", "org2", "org3", "org4", "org5"]

    var body: some View {
        let yesOption = t.t("formOptions.yes")
        let noOption = t.t("formOptions.no")

        ScrollView {
            VStack(alignment: .leading) {

                if !animateTopSearchBar {
                    Text(t.t("flag.explain_why_client_upset"))
                        .padding(.top)
                    LargeTextEditor(text: $upsetReason)

                    Text(t.t("flag.does_issue_involve_you"))
                    let options = [
                        yesOption,
                        noOption
                    ]
                    RadioButtons(selected: $isMyOrgInvolved, options: options)
                        .padding()
                }
                Text(t.t("flag.please_share_other_orgs"))

                HStack {
                    TextField(
                        t.t("profileOrg.organization_name"),
                        text: $viewModel.otherOrgQ
                    )
                    .focused($isQueryFocused)
                    .onChange(of: isQueryFocused) { isFocused in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animateTopSearchBar = isFocused
                        }
                    }
                    .textFieldBorder()

                    if animateTopSearchBar {
                        Button {
                            viewModel.otherOrgQ = ""
                            isQueryFocused = false
                        } label: {
                            Text(t.t("actions.close"))
                        }
                        // TODO: Common dimensions
                        .padding(.leading, 8)
                    }
                }

                if animateTopSearchBar {
                    ForEach(tempOrgs, id:\.self) { org in
                        VStack(alignment: .leading) {
                            Text(org)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        .onTapGesture {
                            viewModel.otherOrgQ = org
                            isQueryFocused = false
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)




        Spacer()

        AddFlagSaveActionBar(
            observeKeyboard: true
        ) {
            let isInvolved = getBoolOptional(
                isMyOrgInvolved,
                yesOption: yesOption,
                noOption: noOption
            )
            viewModel.onUpsetClient(
                notes: upsetReason,
                isMyOrgInvolved: isInvolved,
                otherOrgQuery: viewModel.otherOrgQ,
                otherOrganizationInvolved: selectedOrg
            )
        }
    }
}

private struct ReportAbuse: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    @State var isOrganizationContacted = ""
    @State var outcome = ""
    @State var flagNotes = ""
    @State var flagAction = ""
    @State var selectedOrg: OrganizationIdName? = nil

    @FocusState private var isQueryFocused: Bool
    @State private var animateTopSearchBar = false
    var tempOrgs = ["org1", "org2", "org3", "org4", "org5"]

    var body: some View {
        let yesOption = t.t("formOptions.yes")
        let noOption = t.t("formOptions.no")

        ScrollView {
            VStack(alignment: .leading) {
                Text(t.t("flag.organizations_complaining_about"))
                HStack {
                    TextField(
                        t.t("profileOrg.organization_name"),
                        text: $viewModel.otherOrgQ
                    )
                    .focused($isQueryFocused)
                    .onChange(of: isQueryFocused) { isFocused in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animateTopSearchBar = isFocused
                        }
                    }
                    .textFieldBorder()
                    .padding(.bottom)

                    if animateTopSearchBar {
                        Button {
                            viewModel.otherOrgQ = ""
                            isQueryFocused = false
                        } label: {
                            Text(t.t("actions.close"))
                        }
                        // TODO: Common dimensions
                        .padding(.leading, 8)
                    }
                }

                if !animateTopSearchBar {
                    Text(t.t("flag.must_contact_org_first"))
                        .padding(.bottom)

                    Text(t.t("flag.have_you_contacted_org"))
                    let options = [
                        yesOption,
                        noOption
                    ]
                    RadioButtons(selected: $isOrganizationContacted, options: options)
                        .padding()

                    Group {
                        Text(t.t("flag.outcome_of_contact"))
                            .padding(.top)
                        LargeTextEditor(text: $outcome)

                        Text(t.t("flag.describe_problem"))
                            .padding(.top)
                        LargeTextEditor(text: $flagNotes)

                        Text(t.t("flag.suggested_outcome"))
                            .padding(.top)
                        LargeTextEditor(text: $flagAction)

                        Text(t.t("flag.warning_ccu_cannot_do_much"))
                            .padding(.vertical)
                    }
                } else {
                    ForEach(tempOrgs, id:\.self) { org in
                        VStack(alignment: .leading) {
                            Text(org)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        .onTapGesture {
                            viewModel.otherOrgQ = org
                            isQueryFocused = false
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)

        Spacer()

        AddFlagSaveActionBar(
            observeKeyboard: true
        ) {
            viewModel.onReportAbuse(
                isContacted: getBoolOptional(
                    isOrganizationContacted,
                    yesOption: yesOption,
                    noOption: noOption
                ),
                contactOutcome: outcome,
                notes: flagNotes,
                action: flagAction,
                otherOrgQuery: viewModel.otherOrgQ,
                otherOrganizationInvolved: selectedOrg
            )
        }
    }
}

// TODO: Why does observing the keyboard here fail to work?
private struct WrongLocation: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    @State var isEditable = false

    private let stepTranslateKeys = Array(
        [
            "flag.find_correct_google_maps",
            "flag.zoom_in_completely",
            "flag.copy_paste_url"
        ]
            .enumerated()
    )

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(t.t("flag.move_case_pin"))
                    .padding(.vertical)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading) {
                ForEach(stepTranslateKeys, id: \.offset) { (index, key) in
                    Text("\(index+1). \(t.t(key))")
                    // TODO: Common dimensions
                        .padding(.bottom, 4)
                }
            }
            .padding(.bottom)

            TextField(t.t("flag.google_map_url"), text: viewModel.wrongLocationText)
                .textFieldBorder()
                .padding(.bottom)

            Text(t.t("flag.click_if_location_unknown"))
                .padding(.bottom, 4)

            Button {
                viewModel.onAddFlag(.wrongLocation)
            } label: {
                Text(t.t("flag.location_unknown"))
            }
            .styleBlack()
        }
        .padding(.horizontal)

        Spacer()

        AddFlagSaveActionBar(
            isBusy: viewModel.isProcessingLocation,
            enabled: isEditable,
            enableSave: viewModel.validCoordinates != nil
        ) {
            viewModel.updateLocation(location: viewModel.validCoordinates)
        }
    }
}

private struct WrongIncident: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    let isEditable: Bool

    @State var isNotListed = false
    @State var selectedIncident: IncidentIdNameType? = nil

    @FocusState private var isQueryFocused: Bool
    @State private var animateTopSearchBar = false
    var tempOrgs = ["org1", "org2", "org3", "org4", "org5"]

    var body: some View {
        VStack (alignment: .leading ) {
            Text(t.t("flag.choose_correct_incident"))

            TextField(t.t("casesVue.incident"), text: viewModel.incidentQ)
                .focused($isQueryFocused)
                .onChange(of: isQueryFocused) { isFocused in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animateTopSearchBar = isFocused
                    }
                }
                .textFieldBorder()

            if !animateTopSearchBar {
                CheckboxView(checked: $isNotListed, text: t.t("flag.incident_not_listed"))
            } else {
                ForEach(tempOrgs, id:\.self) { incident in
                    VStack(alignment: .leading) {
                        Text(incident)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                    .onTapGesture {
                        // TODO: assign value
//                        viewModel.incidentQ = incident
                        isQueryFocused = false
                    }
                }
            }
        }
        .padding(.horizontal)

        Spacer()

        let isSelected = isNotListed || selectedIncident?.name == viewModel.incidentQ.wrappedValue
        AddFlagSaveActionBar(enabled: isEditable && isSelected) {
            viewModel.onWrongIncident(
                isIncidentListed: !isNotListed,
                incidentQuery: viewModel.incidentQ.wrappedValue,
                selectedIncident: selectedIncident
            )
        }
    }
}

private struct AddFlagSaveActionBar: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var keyboardVisibilityProvider: KeyboardVisibilityProvider

    var isBusy = false
    var enabled = true
    var enableSave = true
    var observeKeyboard = false

    var save: () -> Void

    var body: some View {
        if observeKeyboard && keyboardVisibilityProvider.isKeyboardVisible {
            OpenKeyboardActionsView()
        } else {
            HStack {
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Text(t.t("actions.cancel"))
                }
                .styleCancel()

                Button {
                    save()
                } label: {
                    BusyButtonContent(
                        isBusy: isBusy,
                        text: t.t("actions.save")
                    )
                }
                .stylePrimary()
                .disabled(!(enabled && enableSave))
            }
            .padding(.horizontal)
        }
    }
}
