import SwiftUI

struct RadioButtons: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Binding var selected: String

    var options: [String]

    var body: some View {
        ForEach(options, id: \.self) {option in
            RadioButton(
                text: t.t(option),
                isSelected: option == selected
            ) {
                selected = option
            }
        }
    }
}

struct RadioButton: View {
    @Environment(\.isEnabled) var isEnabled

    let text: String
    let isSelected: Bool

    var nestedLevel: Int? = nil
    var isListItem: Bool = false

    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                let radioImg = isSelected ? "circle.inset.filled" : "circle"
                Image(systemName: radioImg)
                    .foregroundColor(isSelected && isEnabled ? Color.black : Color.gray)
                    .if (nestedLevel != nil) {
                        $0.padding(.leading, Double(nestedLevel!) * appTheme.nestedItemPadding)
                    }
                Text(text)
                    .foregroundColor(Color.black)
            }
            .if (isListItem) {
                $0.listItemModifier()
            }
        }
    }
}

struct ContentRadioButton<Content>: View where Content: View {
    @Environment(\.isEnabled) var isEnabled

    private let isSelected: Bool
    private let onSelect: () -> Void

    private let nestedLevel: Int?
    private let isListItem: Bool
    private let buttonContentAlignment: VerticalAlignment

    private let content: Content

    init(
        _ isSelected: Bool,
        _ onSelect: @escaping () -> Void,
        nestedLevel: Int? = nil,
        isListItem: Bool = false,
        buttonContentAlignment: VerticalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.nestedLevel = nestedLevel
        self.isListItem = isListItem
        self.buttonContentAlignment = buttonContentAlignment
        self.content = content()
    }

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(alignment: buttonContentAlignment) {
                let radioImg = isSelected ? "circle.inset.filled" : "circle"
                Image(systemName: radioImg)
                    .foregroundColor(isSelected && isEnabled ? Color.black : Color.gray)
                    .if (nestedLevel != nil) {
                        $0.padding(.leading, Double(nestedLevel!) * appTheme.nestedItemPadding)
                    }

                content
            }
            .if (isListItem) {
                $0.listItemModifier()
            }
        }
        .buttonStyle(.plain)
    }
}
