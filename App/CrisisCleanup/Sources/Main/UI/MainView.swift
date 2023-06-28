import SwiftUI

struct MainView: View {
    @Environment(\.translator) var translator

    @ObservedObject var viewModel: MainViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder
    let casesViewBuilder: CasesViewBuilder
    let menuViewBuilder: MenuViewBuilder

    @State private var selectedTab = TopLevelDestination.cases
    var body: some View {
        switch viewModel.viewData.state {
        case .loading:
            // TODO: Show actual splash screen (or loading animation)
            Text("Splash")
        case .ready:
            if viewModel.viewData.showMainContent {
                let navColor = appTheme.colors.navigationContainerColor
                NavigationStack {
                    ZStack {
                        navColor.ignoresSafeArea()
                        VStack {
                            // TODO: Change status icon colors without this empty Text
                            Text("")

                            TabView {
                                Group {
                                    TabViewContainer {
                                        casesViewBuilder.casesView
                                    }
                                    .navTabItem(.cases, viewModel.translator)
                                    .tag(TopLevelDestination.cases)

                                    TabViewContainer {
                                        menuViewBuilder.menuView
                                    }
                                    .navTabItem(.menu, viewModel.translator)
                                    .tag(TopLevelDestination.menu)
                                }
                                .toolbarColorScheme(.light, for: .tabBar)
                            }
                        }
                    }
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarColorScheme(.light, for: .navigationBar)
                }
                .environment(\.translator, viewModel.translator)
            } else {
                authenticateViewBuilder.authenticateView
                    .environment(\.translator, viewModel.translator)
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            }
        }
    }
}

private struct TabViewContainer<Content: View>: View {
    let backgroundColor: Color
    let bottomPadding: CGFloat?

    private let content: Content

    init(
        backgroundColor: Color = appTheme.colors.navigationContainerColor,
        bottomPadding: CGFloat? = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.bottomPadding = bottomPadding
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack {
                content

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: bottomPadding)
            }
        }
    }
}
