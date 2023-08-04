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
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack{
                let radioImg = isSelected ? "circle.inset.filled" : "circle"
                Image(systemName: radioImg)
                    .foregroundColor(isSelected ? Color.black : Color.gray)
                Text(text)
                    .foregroundColor(Color.black)

            }
        }
    }
}
