import SwiftUI

struct FullWidthSelectModifier: ViewModifier {
    // TODO: Common dimensions
    var height: CGFloat = 48

    func body(content: Content) -> some View {
        return content
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: height)
            .contentShape(Rectangle())
    }
}

extension View {
    func fullWidthSelector(
        height: CGFloat = 48.0
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: FullWidthSelectModifier(height: height)
        )
    }
}
