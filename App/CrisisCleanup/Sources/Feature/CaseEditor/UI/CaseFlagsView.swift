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

        switch selected {
        case WorksiteFlagType.highPriority:
            HighPriority()
                .environmentObject(viewModel)

        case WorksiteFlagType.upsetClient:
            UpsetClient()
                .environmentObject(viewModel)

        case WorksiteFlagType.markForDeletion:
            EmptyView()

        case WorksiteFlagType.reportAbuse:
            ReportAbuse()
                .environmentObject(viewModel)

        case WorksiteFlagType.duplicate:
            EmptyView()

        case WorksiteFlagType.wrongLocation:
            WrongLocation()
                .environmentObject(viewModel)

        case WorksiteFlagType.wrongIncident:
            WrongIncident()
                .environmentObject(viewModel)

        }

        Spacer()
    }
}

struct HighPriority: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel
    @State var showContactSheet: Bool = false

    @State var tempString = ""
    var nearbyOrganizations: [IncidentOrganization] = [
        IncidentOrganization(id: 1, name: "Orginization Name Here", primaryContacts: [PersonContact(id: 1, firstName: "temp", lastName: "temp", email: "temp@temp.com", mobile: "1234567890")], affiliateIds: Set(arrayLiteral: 1))
    ]

    var body: some View {

        // TODO: Check box

        VStack(alignment: .leading) {
            Text(t.t("flag.please_describe_why_high_priority"))

            LargeTextEditor(text: $tempString)
//                .padding()

            Text(viewModel.nearbyOrganizations?.debugDescription ?? "nil")

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
                            .sheet(isPresented: $showContactSheet) {
                                VStack {
                                    Text("contact sheet under construction")
                                }
                                .foregroundColor(Color.black)
                            }
                    }
                }
//            }
        }
        .padding(.horizontal)
    }
}

struct UpsetClient: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    var body: some View {
        Text(WorksiteFlagType.upsetClient.literal)
    }
}

struct ReportAbuse: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    var body: some View {
        Text(WorksiteFlagType.reportAbuse.literal)
    }
}

struct WrongLocation: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    var body: some View {
        Text(WorksiteFlagType.wrongLocation.literal)
    }
}

struct WrongIncident: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseFlagsViewModel

    var body: some View {
        Text(WorksiteFlagType.wrongIncident.literal)
    }
}
