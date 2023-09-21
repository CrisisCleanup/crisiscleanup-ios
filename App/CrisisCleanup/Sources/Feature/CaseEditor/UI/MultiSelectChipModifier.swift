import SwiftUI

struct MultiSelectChipModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled

    var isSelected: Bool

    func body(content: Content) -> some View {
        var backgroundColor = isSelected ? appTheme.colors.themePrimaryContainer : Color.white
        if !isEnabled {
            backgroundColor = backgroundColor.disabledAlpha()
        }
        var borderColor = Color.black
        if !isEnabled && !isSelected {
            borderColor = borderColor.disabledAlpha()
        }
        return content
            .fontBodySmall()
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(backgroundColor)
        // TODO: Full radius no magic numbers
            .cornerRadius(40)
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        borderColor,
                        lineWidth: isSelected ? 0 : 1
                    )
            )
    }
}

extension Text {
    func styleMultiSelectChip(_ isSelected: Bool = false) -> some View {
        ModifiedContent(content: self, modifier: MultiSelectChipModifier(isSelected: isSelected))
    }
}
