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
                            // TODO: Why is a view required to change system bar (and tab bar) backgrounds?
                            Rectangle()
                                .fill(.clear)
                                .frame(height: 0)
                                .background(.clear)

                            TabView(selection: $selectedTab) {
                                Group {
                                    TabViewContainer {
                                        casesViewBuilder.casesView
                                    }
                                    .navTabItem(.cases, viewModel.translator)
                                    .tag(TopLevelDestination.cases)

                                    TabViewContainer(
                                        bottomPadding: 0,
                                        addBottomRect: true
                                    ) {
                                        menuViewBuilder.menuView
                                    }
                                    .navTabItem(.menu, viewModel.translator)
                                    .tag(TopLevelDestination.menu)
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
