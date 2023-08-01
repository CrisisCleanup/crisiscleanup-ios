import SwiftUI

struct CaseFlagsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseFlagsViewModel

    @State var selected: WorksiteFlagType? = nil

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
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)

            switch selected {
            case .some (let unwrapped):
                switch unwrapped {
                case WorksiteFlagType.highPriority:
                    HighPriority()

                case WorksiteFlagType.upsetClient:
                    UpsetClient()

                case WorksiteFlagType.markForDeletion:
                    Spacer()
                    ActionButtons {
                        viewModel.onAddFlag(.markForDeletion)
                    }

                case WorksiteFlagType.reportAbuse:
                    ReportAbuse()

                case WorksiteFlagType.duplicate:
                    Spacer()
                    ActionButtons {
                        viewModel.onAddFlag(.duplicate)
                    }

                case WorksiteFlagType.wrongLocation:
                    WrongLocation()

                case WorksiteFlagType.wrongIncident:
                    WrongIncident()
                }
            default:
                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(t.t("nav.flag"))
            }
        }
        .environmentObject(viewModel)
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
            HStack {
                Text(org.name)
                    .font(.title)
                    .padding(.top)
                Spacer()
            }
            Text(t.t("flag.primary_contacts"))
                .font(.title2)
                .padding(.bottom)


            ForEach(org.primaryContacts, id: \.id) { contact in

                Text(contact.fullName)
                    .bold()
                    .padding(.bottom, 4)

                if contact.email.isNotBlank {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Link(contact.email, destination: URL(string: "mailto:\(contact.email)")!)
                    }
                    .padding(.bottom, 4)
                }

                HStack {
                    Image(systemName: "phone.fill")
                    Link(contact.mobile, destination: URL(string: "tel:\(contact.mobile)")!)
                }
                .padding(.bottom, 8)
            }

            Spacer()
        }
        .padding(.horizontal)

    }
}

struct HighPriority: View {
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

        Spacer()

        ActionButtons {
            viewModel.onHighPriority(isHighPriority, flagDescription)
        }
    }
}

struct UpsetClient: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    @State var tempString = ""
    @State var tempSelected = ""

    var body: some View {
        VStack(alignment: .leading) {

            Text(t.t("flag.explain_why_client_upset"))

            LargeTextEditor(text: $tempString)
                .padding(.vertical)

            HStack {
                Text(t.t("flag.does_issue_involve_you"))
                Spacer ()
            }

            let options = [t.t("formOptions.yes"), t.t("formOptions.no") ]

            RadioButtons(selected: $tempSelected, options: options)
                .padding()

            Text(t.t("flag.please_share_other_orgs"))

            TextField(t.t("profileOrg.organization_name"), text: $tempString)
                .textFieldBorder()
        }
        .padding(.horizontal)

        Spacer()

        // TODO: replace placeholders
        ActionButtons {
            viewModel.onUpsetClient(notes: tempString, isMyOrgInvolved: true, otherOrgQuery: tempString, otherOrganizationsInvolved: [OrganizationIdName(id: 1, name: "temp")])
        }
    }
}

struct ReportAbuse: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    @State var tempString = ""
    @State var tempSelected = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(t.t("flag.organizations_complaining_about"))

                Text(t.t("flag.must_contact_org_first"))

                LargeTextEditor(text: $tempString)
                    .padding(.vertical)

                HStack {
                    Text(t.t("flag.have_you_contacted_org"))
                    Spacer ()
                }

                let options = [t.t("formOptions.yes"), t.t("formOptions.no") ]

                RadioButtons(selected: $tempSelected, options: options)
                    .padding()

                Group {
                    Text(t.t("flag.outcome_of_contact"))

                    LargeTextEditor(text: $tempString)
                        .padding(.vertical)

                    Text(t.t("flag.describe_problem"))

                    LargeTextEditor(text: $tempString)
                        .padding(.vertical)

                    Text(t.t("flag.suggested_outcome"))

                    LargeTextEditor(text: $tempString)
                        .padding(.vertical)

                    Text(t.t("flag.warning_ccu_cannot_do_much"))
                }
            }
            .padding(.horizontal)
        }

        Spacer()

        // TODO: replace placeholders
        ActionButtons {
            viewModel.onReportAbuse(isContacted: true, contactOutcome: tempString, notes: tempString, action: tempString)
        }

    }
}

struct WrongLocation: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    @State var tempString = ""

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(t.t("flag.move_case_pin"))
                    .padding(.vertical)
                Spacer()
            }

            VStack(alignment: .leading) {
                Text("1. " + t.t("flag.find_correct_google_maps"))
                    .padding(.bottom, 4)
                Text("2. " + t.t("flag.zoom_in_completely"))
                    .padding(.bottom, 4)
                Text("3. " + t.t("flag.copy_paste_url"))
                    .padding(.bottom, 4)
            }
            .padding(.bottom)

            TextField(t.t("flag.google_map_url"), text: $tempString)
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

        // TODO: replace placeholders
        ActionButtons {
            viewModel.updateLocation(location: nil)
        }
    }
}

struct WrongIncident: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    @State var tempString = ""
    @State var tempChecked = false

    var body: some View {
        VStack (alignment: .leading ) {
            HStack {
                Text(t.t("flag.choose_correct_incident"))
                Spacer()
            }

            TextField(t.t("casesVue.incident"), text: $tempString)
                .textFieldBorder()

            CheckboxView(checked: $tempChecked, text: t.t("flag.incident_not_listed"))

        }
        .padding(.horizontal)

        Spacer()

        // TODO: replace placeholders
        ActionButtons {
            viewModel.onWrongIncident(isIncidentListed: true, incidentQuery: tempString, selectedIncident: nil)
        }
    }
}

struct ActionButtons: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    var save: () -> Void

    var body: some View {
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
                Text(t.t("actions.save"))
            }
            .stylePrimary()
        }
        .padding(.horizontal)
    }
}
