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
                    .foregroundColor(isSelected ? Color.black : Color.gray)
                    .if(nestedLevel != nil) {
                        // TODO: Common dimensions
                        $0.padding(.leading, Double(nestedLevel!) * 16)
                    }
                Text(text)
                    .foregroundColor(Color.black)
            }
            .if(isListItem) {
                $0
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: appTheme.rowItemHeight, alignment: .leading)
            }
        }
    }
}
