import SwiftUI

struct BorderModifier: ViewModifier {
    // TODO: Change text and border color based on state (disabled, selected, ...). Create style.
    var color: Color = .gray
    var lineWidth: CGFloat = 1.0

    func body(content: Content) -> some View {
        return content
            .overlay(
                RoundedRectangle(cornerRadius: appTheme.cornerRadius)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

extension View {
    func roundedBorder(
        color: Color = .gray,
        lineWidth: CGFloat = appTheme.textFieldOutlineWidth
    ) -> some View {
        ModifiedContent(
            content: self,
            modifier: BorderModifier(color: color, lineWidth: lineWidth)
        )
    }
}
