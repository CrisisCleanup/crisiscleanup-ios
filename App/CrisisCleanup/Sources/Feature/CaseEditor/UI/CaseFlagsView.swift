import SwiftUI

struct CaseFlagsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseFlagsViewModel

    @State var selected: WorksiteFlagType = .highPriority

    var body: some View {
        VStack {
            HStack {
                Text(t.t("events.object_flag"))

                let options = viewModel.flagFlows
                Picker("", selection: $selected) {
                    ForEach(options, id: \.self) { option in
                        Text(t.t(option.literal))
                    }
                }
                Spacer()

            }
        }
        .padding(.horizontal)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }

        Group {
            switch selected {
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
        }
        .environmentObject(viewModel)
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

    @State var highPriority: Bool = false
    @State var tempString = ""
    var nearbyOrganizations: [IncidentOrganization] = [
        IncidentOrganization(id: 1, name: "Orginization Name Here", primaryContacts: [
            PersonContact(id: 1, firstName: "first", lastName: "last", email: "temp@temp.com", mobile: "1234567890"),
            PersonContact(id: 2, firstName: "John", lastName: "Doe", email: "John@Doe.com", mobile: "1234567890")
        ], affiliateIds: Set(arrayLiteral: 1)),

    ]

    var body: some View {

        VStack(alignment: .leading) {

            CheckboxView(
                checked: $highPriority,
                text: t.t("flag.flag_high_priority")
            )

            Text(t.t("flag.please_describe_why_high_priority"))

            LargeTextEditor(text: $tempString)
            //                .padding()

            //            if let nearbyOrganizations = viewModel.nearbyOrganizations {
            Text(t.t("flag.nearby_organizations"))
                .bold()
                .padding(.bottom, 4)

            Text(t.t("caseHistory.do_not_share_contact_warning"))
                .bold()
                .padding(.bottom, 4)

            Text(t.t("caseHistory.do_not_share_contact_explanation"))
                .padding(.bottom)

            ForEach(nearbyOrganizations, id:\.id) { org in

                Button {
                    showContactSheet = true
                } label : {
                    Text(t.t(org.name))
                }
                .padding(.vertical)
                .sheet(isPresented: $showContactSheet) {
                    ContactSheet(org: org)
                }
            }

            //            }
        }
        .padding(.horizontal)

        Spacer()

        ActionButtons {
            viewModel.onHighPriority(highPriority, tempString)
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
