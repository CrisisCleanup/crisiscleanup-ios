import SwiftUI

struct ScreenTitleModifier: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        return content.toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .fontHeader3()
            }
        }
    }
}

extension View {
    func screenTitle(_ title: String) -> some View {
        ModifiedContent(content: self, modifier: ScreenTitleModifier(title: title))
    }
}
