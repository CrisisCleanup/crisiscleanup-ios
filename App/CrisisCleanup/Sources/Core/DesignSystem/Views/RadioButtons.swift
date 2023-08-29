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
            HStack{
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
