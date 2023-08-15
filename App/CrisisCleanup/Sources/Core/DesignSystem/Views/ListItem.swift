import SwiftUI

struct ListItemModifier: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .padding(.horizontal)
            .padding(.vertical, appTheme.listItemVerticalPadding)
    }
}

extension View {
    func listItemModifier() -> some View {
        ModifiedContent(content: self, modifier: ListItemModifier())
    }
}
