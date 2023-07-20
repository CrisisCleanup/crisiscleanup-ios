import SwiftUI

// From https://swiftuirecipes.com/blog/swiftui-tabview-styling-all-ios-versions

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}

extension View {
    func tabViewStyle(
        backgroundColor: Color? = nil,
        itemColor: Color? = nil,
        selectedItemColor: Color? = nil,
        badgeColor: Color? = nil
    ) -> some View {
        onAppear {
            let itemAppearance = UITabBarItemAppearance()
            if let uiItemColor = itemColor?.uiColor {
                itemAppearance.normal.iconColor = uiItemColor
                itemAppearance.normal.titleTextAttributes = [
                    .foregroundColor: uiItemColor
                ]
            }
            if let uiSelectedItemColor = selectedItemColor?.uiColor {
                itemAppearance.selected.iconColor = uiSelectedItemColor
                itemAppearance.selected.titleTextAttributes = [
                    .foregroundColor: uiSelectedItemColor
                ]
            }
            if let uiBadgeColor = badgeColor?.uiColor {
                itemAppearance.normal.badgeBackgroundColor = uiBadgeColor
                itemAppearance.selected.badgeBackgroundColor = uiBadgeColor
            }

            let appearance = UITabBarAppearance()
            if let uiBackgroundColor = backgroundColor?.uiColor {
                appearance.backgroundColor = uiBackgroundColor
            }

            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
