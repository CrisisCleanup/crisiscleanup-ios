import SwiftUI

struct ListItemPadding: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .padding(.horizontal)
            .padding(.vertical, appTheme.listItemVerticalPadding)
    }
}

struct ListItemModifier: ViewModifier {
    func body(content: Content) -> some View {
        return content
            .listItemPadding()
            .frame(maxWidth: .infinity, minHeight: appTheme.rowItemHeight, alignment: .leading)
    }
}

extension View {
    func listItemPadding() -> some View {
        ModifiedContent(content: self, modifier: ListItemPadding())
    }

    func listItemModifier() -> some View {
        ModifiedContent(content: self, modifier: ListItemModifier())
    }
}
