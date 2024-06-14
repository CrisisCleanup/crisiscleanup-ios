import Combine
import SVGView
import SwiftUI

struct ListsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: ListsViewModel

    @State private var showReadOnlyDescription = false
    @State private var selectedTab = ListsTab.incidents
    @State private var animateIsRefreshing = false

    private let listTabs = Array([
        ListsTab.incidents,
        ListsTab.all,
    ].enumerated())

    var body: some View {
        let tabTitles = viewModel.tabTitles

        ZStack {
            VStack {
                HStack {
                    ForEach(listTabs, id: \.offset) { (index, tab) in
                        VStack {
                            HStack{
                                Spacer()
                                Text(tabTitles[tab] ?? "")
                                    .fontHeader4()
                                    .onTapGesture {
                                        selectedTab = tab
                                    }
                                Spacer()
                            }
                            Divider()
                                .frame(height: 2)
                                .background(selectedTab == tab ? Color.orange : Color.gray)
                        }
                    }
                }

                TabView(selection: $selectedTab) {
                    IncidentListsView(
                        animateIsRefreshing: $animateIsRefreshing
                    )
                    .tag(ListsTab.incidents)
                    AllListsView(
                        animateIsRefreshing: $animateIsRefreshing
                    )
                    .tag(ListsTab.all)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: viewModel.isRefreshingData) { newValue in
                    animateIsRefreshing = newValue
                }
            }

            if showReadOnlyDescription {
                AlertDialog(
                    title: t.t("~~Lists are read-only"),
                    positiveActionText: t.t("actions.ok"),
                    negativeActionText: "",
                    dismissDialog: {
                        showReadOnlyDescription = false
                    },
                    positiveAction: {
                        showReadOnlyDescription = false
                    }
                ) {
                    Text(t.t("~~Lists (in this app) are currently read-only. Manage lists using Crisis Cleanup on the browser."))
                }
            }
        }
        .hideNavBarUnderSpace()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(t.t("~~Lists"))
                    .fontHeader3()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "info.circle.fill")
                    .onTapGesture {
                        showReadOnlyDescription = true
                    }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct IncidentListsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ListsViewModel

    @Binding var animateIsRefreshing: Bool

    var body: some View {
        let lists = viewModel.incidentLists

        ScrollView {
            LazyVStack(alignment: .leading) {
                IncidentHeaderView(
                    incident: viewModel.currentIncident
                )
                .listItemPadding()

                if lists.isEmpty {
                    Text(t.t("~~No lists have been created for this Incident."))
                        .listItemModifier()

                } else {
                    ForEach(viewModel.incidentLists, id: \.id) { list in
                        ListItemSummaryView(list: list)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                router.viewList(list)
                            }
                    }
                }
            }
        }
        .refreshable {
            viewModel.refreshLists(true)
        }

        if animateIsRefreshing {
            ProgressView()
                .padding()
        }
    }
}


private struct AllListsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ListsViewModel

    @Binding var animateIsRefreshing: Bool

    var body: some View {
        ScrollView {
            LazyVStack {
                // TODO: Find/develop reactive item paging pattern
                ForEach(viewModel.allListIds, id: \.self) { listId in
                    let listData = viewModel.getListData(listId)
                    if listData.id == EmptyList.id {
                        ProgressView()
                            .padding()
                    } else {
                        ListItemSummaryView(
                            list: listData,
                            showIncident: true
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            router.viewList(listData)
                        }
                    }
                }

                if viewModel.isLoadingAdditional {
                    ProgressView()
                        .padding()
                }

                Rectangle()
                    .fill(.clear)
                    .frame(width: UIScreen.main.bounds.width, height: 1)
                    .onAppear {
                        viewModel.onScrollToLastItem()
                    }
            }
        }
        .refreshable {
            viewModel.refreshLists(true)
        }

        if animateIsRefreshing {
            ProgressView()
                .padding()
        }
    }
}

internal struct ListItemSummaryView: View {
    var list: CrisisCleanupList

    var showIncident = false

    var body: some View {
        VStack(alignment: .leading, spacing: appTheme.gridItemSpacing) {
            Color.clear

            HStack(spacing: appTheme.gridItemSpacing) {
                list.ListIcon
                Text("\(list.name) (\(list.objectIds.count))")
                    .fontHeader3()
                Spacer()
                Text(list.updatedAt.relativeTime)
            }

            let incidentName = showIncident ? (list.incident?.shortName ?? "") : ""
            let description = list.description.trim()
            let hasIncident = incidentName.isNotBlank
            let hasDescription = description.isNotBlank
            if hasIncident || hasDescription {
                HStack(spacing: appTheme.gridItemSpacing) {
                    Text(description)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasIncident {
                        Text(incidentName)
                    }
                }
            }
        }
        .listItemModifier()
        .frame(minHeight: appTheme.rowItemHeight)
    }
}
