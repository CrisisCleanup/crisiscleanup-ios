import SwiftUI

// Modified from https://stackoverflow.com/questions/57517803/how-to-remove-the-default-navigation-bar-space-in-swiftui-navigationview
struct HideNavBarUnderSpace: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitle("", displayMode: .inline)
    }
}

extension View {
    func hideNavBarUnderSpace() -> some View {
        modifier( HideNavBarUnderSpace() )
    }
}
