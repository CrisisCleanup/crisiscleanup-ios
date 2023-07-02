import SwiftUI

struct MainView: View {
    @Environment(\.translator) var translator

    @ObservedObject var router = NavigationRouter()

    @ObservedObject var viewModel: MainViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder
    let casesViewBuilder: CasesViewBuilder
    let menuViewBuilder: MenuViewBuilder
    let casesFilterViewBuilder: CasesFilterViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder
    let viewCaseViewBuilder: ViewCaseViewBuilder

    @State private var selectedTab = TopLevelDestination.cases
    var body: some View {
        Group {
            switch viewModel.viewData.state {
            case .loading:
                // TODO: Show actual splash screen (or loading animation)
                Text("Splash/loading")
            case .ready:
                if viewModel.viewData.showMainContent {
                    let navColor = appTheme.colors.navigationContainerColor
                    NavigationStack(path: $router.path) {
                        ZStack {
                            navColor.ignoresSafeArea()
                            VStack {
                                // TODO: Why is a view required to change system bar (and tab bar) backgrounds?
                                Rectangle()
                                    .fill(.clear)
                                    .frame(height: 0)
                                    .background(.clear)

                                TabView(selection: $selectedTab) {
                                    Group {
                                        MainTabs(
                                            viewModel: viewModel,
                                            authenticateViewBuilder: authenticateViewBuilder,
                                            casesViewBuilder: casesViewBuilder,
                                            menuViewBuilder: menuViewBuilder,
                                            casesFilterViewBuilder: casesFilterViewBuilder,
                                            casesSearchViewBuilder: casesSearchViewBuilder,
                                            viewCaseViewBuilder: viewCaseViewBuilder
                                        )
                                    }
                                    .toolbarColorScheme(.light, for: .tabBar)
                                }
                                // TODO: Tinting here will cause all downstream views to reverse the tint...
                                //       Find a more targeted solution
                                //.tint(.white)
                            }
                        }
                        .toolbarBackground(.visible, for: .navigationBar)
                        .toolbarColorScheme(.light, for: .navigationBar)
                    }
                } else {
                    authenticateViewBuilder.authenticateView
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environment(\.translator, viewModel.translator)
        .environmentObject(router)
    }
}

private struct TabViewContainer<Content: View>: View {
    let backgroundColor: Color
    let bottomPadding: CGFloat?
    let addBottomRect: Bool

    private let content: Content

    init(
        backgroundColor: Color = appTheme.colors.navigationContainerColor,
        bottomPadding: CGFloat? = 8,
        addBottomRect: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.bottomPadding = bottomPadding
        self.addBottomRect = addBottomRect
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack {
                content

                if addBottomRect {
                    Rectangle()
                        .fill(backgroundColor)
                        // TODO: Setting a positive height causes flickering in Cases tab.
                        //       Figure out how to add space without flickering for all content.
                        .frame(height: bottomPadding)
                        .background(backgroundColor)
                }
            }
        }
    }
}

private struct MainTabs: View {
    @ObservedObject var viewModel: MainViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder
    let casesViewBuilder: CasesViewBuilder
    let menuViewBuilder: MenuViewBuilder
    let casesFilterViewBuilder: CasesFilterViewBuilder
    let casesSearchViewBuilder: CasesSearchViewBuilder
    let viewCaseViewBuilder: ViewCaseViewBuilder

    var body: some View {
        TabViewContainer {
            casesViewBuilder.casesView
                .navigationDestination(for: NavigationRoute.self) { route in
                    switch route {
                    case .authenticate:
                        authenticateViewBuilder.authenticateView
                            .navigationBarHidden(true)
                            .onAppear { viewModel.onViewDisappear() }
                            .onDisappear { viewModel.onViewAppear() }
                    case .filterCases:
                        casesFilterViewBuilder.casesFilterView
                    case .searchCases:
                        casesSearchViewBuilder.casesSearchView
                            .navigationBarHidden(true)
                    case .viewCase(let incidentId, let worksiteId):
                        viewCaseViewBuilder.viewCaseView(
                            incidentId: incidentId,
                            worksiteId: worksiteId
                        )
                    default:
                        Text("Route \(route.id) needs implementing")
                    }
                }
        }
        .navTabItem(.cases, viewModel.translator)
        .tag(TopLevelDestination.cases)

        TabViewContainer(
            bottomPadding: 0,
            addBottomRect: true
        ) {
            menuViewBuilder.menuView
            // Prior routes are used
        }
        .navTabItem(.menu, viewModel.translator)
        .tag(TopLevelDestination.menu)
    }
}
