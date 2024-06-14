import SwiftUI

struct ViewListView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: ViewListViewModel

    @State private var animateIsLoading = true

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
                    list: viewState.list,
                    objectData: viewState.objectData
                )
            }

            if animateIsLoading {
                ProgressView()
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

    var list: CrisisCleanupList
    var objectData: [Any?] = []

    var body: some View {
        VStack(alignment: .leading) {
            if objectData.isEmpty {
                Text(t.t("~~This list is not supported by the app or has no items."))
                    .listItemModifier()
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
                            ListItemsView(listData: objectData)
                        case .organization:
                            OrganizationItemsView(listData: objectData)
                        case .user:
                            UserItemsView(listData: objectData)
                        case .worksite:
                            WorksiteItemsView(listData: objectData)
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
                    .id("missing-item")
            }
        }
    }
}

private struct ListItemsView: View {
    var lists: [(Int64, CrisisCleanupList?)] = []

    // TODO: Open list

    init(listData: [Any?]) {
        lists = listData.enumerated()
            .map { i, v in
                let value = v as? CrisisCleanupList
                return (value?.id ?? Int64(-i), value)
            }
    }

    var body: some View {
        ForEach(lists, id: \.0) { (_, list) in
            if let list = list {
                ListItemSummaryView(
                    list: list,
                    showIncident: true
                )
                .onTapGesture {
                    // TODO: Open to list
                    print("Open list \(list)")
                }
            } else {
                MissingItemView()
                    .id("missing-item")
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
                    .id("missing-item")
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
                    .id("missing-item")
            }
        }
    }
}

private struct WorksiteItemsView: View {
    var worksites: [(Int64, Worksite?)] = []

    init(listData: [Any?]) {
        worksites = listData.enumerated()
            .map { i, v in
                let value = v as? Worksite
                return (value?.id ?? Int64(-i), value)
            }
    }

    var body: some View {
        ForEach(worksites, id: \.0) { (_, worksite) in
            if let worksite = worksite {
                Text(worksite.name)
                    .listItemModifier()
            } else {
                MissingItemView()
                    .id("missing-item")
            }
        }
    }
}
