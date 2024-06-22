import SwiftUI

struct ViewListView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: ViewListViewModel

    @State private var animateIsLoading = true

    @State private var phoneCallNumbers = [ParsedPhoneNumber]()

    var body: some View {
        let viewState = viewModel.viewState
        ZStack {
            if viewState.errorMessage.isNotBlank {
                VStack(alignment: .leading) {
                    Text(viewState.errorMessage)
                        .listItemModifier()

                    Spacer()
                }
            } else if !viewState.isLoading {
                ListDetailView(
                    phoneCallNumbers: $phoneCallNumbers,
                    phoneNumberParser: viewModel.phoneNumberParser,
                    list: viewState.list,
                    objectData: viewState.objectData
                )
            }

            if animateIsLoading {
                ProgressView()
            }

            if phoneCallNumbers.isNotEmpty {
                PhoneCallDialog(phoneNumbers: phoneCallNumbers) {
                    phoneCallNumbers = []
                }
            }
        }
        .onChange(of: viewState.isLoading) { newValue in
            withAnimation {
                animateIsLoading = newValue
            }
        }
        .screenTitle(viewModel.screenTitle)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct ListDetailView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @Binding var phoneCallNumbers: [ParsedPhoneNumber]

    var phoneNumberParser: PhoneNumberParser
    var list: CrisisCleanupList
    var objectData: [Any?] = []

    var body: some View {
        VStack(alignment: .leading) {
            if objectData.isEmpty {
                Text(t.t("~~This list is not supported by the app or has no items."))
                    .listItemModifier()

                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            if let incident = list.incident {
                                IncidentHeaderView(
                                    isValidIncident: incident.id != EmptyIncident.id,
                                    disasterLiteral: incident.disasterLiteral,
                                    text: incident.shortName
                                )
                                .listItemModifier()
                            }

                            HStack(spacing: appTheme.gridItemSpacing) {
                                list.ListIcon
                                Text(list.updatedAt.relativeTime)
                            }
                            .listItemPadding()

                            let description = list.description.trim()
                            if description.isNotBlank {
                                Text(description)
                                    .listItemPadding()
                            }
                        }

                        switch list.model {
                        case .incident:
                            IncidentItemsView(listData: objectData)
                        case .list:
                            ListItemsView(listData: objectData) { list in
                                router.viewList(list)
                            }
                        case .organization:
                            OrganizationItemsView(listData: objectData)
                        case .user:
                            UserItemsView(listData: objectData)
                        case .worksite:
                            WorksiteItemsView(
                                incidentId: list.incidentId,
                                listData: objectData,
                                phoneNumberParser: phoneNumberParser,
                                phoneCallNumbers: $phoneCallNumbers
                            ) { worksite in
                                // TODO: Route to case
                                print("Open Case \(worksite)")
                            }
                        default:
                            Text(t.t("~~This list is not supported by the app."))
                                .listItemModifier()
                        }
                    }
                }
            }
        }
    }
}

private struct MissingItemView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        Text(t.t("~~Missing list data."))
            .listItemModifier()
    }
}

private struct IncidentItemsView: View {
    private let incidents: [(Int64, Incident?)]

    init(listData: [Any?]) {
        incidents = listData.enumerated()
            .map { i, v in
                let value = v as? Incident
                return (value?.id ?? Int64(-i), value)
            }
    }

    var body: some View {
        ForEach(incidents, id: \.0) { (_, incident) in
            if let incident = incident {
                IncidentHeaderView(incident: incident)
                    .listItemModifier()
            } else {
                MissingItemView()
            }
        }
    }
}

private struct ListItemsView: View {
    private let lists: [(Int64, CrisisCleanupList?)]
    private let onOpenList: (CrisisCleanupList) -> Void

    init(
        listData: [Any?],
        onOpenList: @escaping (CrisisCleanupList) -> Void
    ) {
        lists = listData.enumerated()
            .map { i, v in
                let value = v as? CrisisCleanupList
                return (value?.id ?? Int64(-i), value)
            }
        self.onOpenList = onOpenList
    }

    var body: some View {
        ForEach(lists, id: \.0) { (_, list) in
            if let list = list {
                ListItemSummaryView(
                    list: list,
                    showIncident: true
                )
                .onTapGesture {
                    onOpenList(list)
                }
            } else {
                MissingItemView()
            }
        }
    }
}

private struct OrganizationItemsView: View {
    var organizations: [(Int64, IncidentOrganization?)] = []

    init(listData: [Any?]) {
        organizations = listData.enumerated()
            .map { i, v in
                let value = v as? IncidentOrganization
                return (value?.id ?? Int64(-i), value)
            }
    }

    var body: some View {
        ForEach(organizations, id: \.0) { (_, organization) in
            if let organization = organization {
                Text(organization.name)
                    .listItemModifier()
            } else {
                MissingItemView()
            }
        }
    }
}

private struct UserItemsView: View {
    var users: [(Int64, PersonContact?)] = []

    init(listData: [Any?]) {
        users = listData.enumerated()
            .map { i, v in
                let value = v as? PersonContact
                return (value?.id ?? Int64(-i), value)
            }
    }

    // TODO: Test on user list
    var body: some View {
        ForEach(users, id: \.0) { (_, contact) in
            if let contact = contact {
                VStack(alignment: .leading, spacing: appTheme.gridItemSpacing) {
                    Text(contact.fullName)
                    if contact.mobile.isNotBlank,
                       let phoneUri = URL(string: "tel:\(contact.mobile)") {
                        Link(contact.mobile, destination: phoneUri)
                    }
                    if contact.email.isNotBlank,
                       let emailUri = URL(string: "mailto:\(contact.email)") {
                        Link(contact.email, destination: emailUri)
                    }
                }
                .listItemModifier()
            } else {
                MissingItemView()
            }
        }
    }
}

private struct WorksiteItemsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    private let incidentId: Int64
    private let worksites: [(Int64, Worksite?)]
    private let phoneNumberParser: PhoneNumberParser
    private let onOpenCase: (Worksite) -> Void

    @Binding var phoneCallNumbers: [ParsedPhoneNumber]

    @State private var showWrongLocationDialog = false

    init(
        incidentId: Int64,
        listData: [Any?],
        phoneNumberParser: PhoneNumberParser,
        phoneCallNumbers: Binding<[ParsedPhoneNumber]>,
        onOpenCase: @escaping (Worksite) -> Void
    ) {
        self.incidentId = incidentId
        worksites = listData.enumerated()
            .map { i, v in
                let value = v as? Worksite
                let id = if let worksite = value,
                    worksite != EmptyWorksite {
                        worksite.id
                    } else {
                        Int64(-i)
                    }
                return (id, value)
            }
        self.phoneNumberParser = phoneNumberParser
        self._phoneCallNumbers = phoneCallNumbers
        self.onOpenCase = onOpenCase
    }

    var body: some View {
        ForEach(worksites, id: \.0) { (_, worksite) in
            if let worksite = worksite {
                if worksite == EmptyWorksite {
                    MissingItemView()

                } else if worksite.incidentId == incidentId {
                    let (fullAddress, addressMapItem) = worksite.addressQuery

                    VStack(alignment: .leading, spacing: appTheme.gridItemSpacing) {
                        Text(worksite.caseNumber)
                            .fontHeader3()

                        WorksiteNameView(name: worksite.name)

                        WorksiteAddressView(fullAddress: fullAddress) {
                            if worksite.hasWrongLocationFlag {
                                ExplainWrongLocationDialog(showDialog: $showWrongLocationDialog)
                            }
                        }

                        HStack {
                            WorksiteCallButton(
                                phone1: worksite.phone1,
                                phone2: worksite.phone2,
                                enable: true,
                                phoneNumberParser: phoneNumberParser
                            ) { parsedNumbers in
                                phoneCallNumbers = parsedNumbers
                            }

                            WorksiteAddressButton(
                                addressMapItem: addressMapItem,
                                enable: true
                            )
                        }
                    }
                    // TODO: Open Case when tapping blank space
                    .onTapGesture {
                        onOpenCase(worksite)
                    }
                    .listItemModifier()

                } else {
                    Text(
                        t.t("~~Case {case_number} is not under this Incident.")
                            .replacingOccurrences(of: "{case_number}", with: worksite.caseNumber)
                    )
                    .listItemModifier()
                }

            } else {
                MissingItemView()
            }
        }
    }
}
