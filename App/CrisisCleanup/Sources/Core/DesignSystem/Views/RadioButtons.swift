import SwiftUI

struct RadioButtons: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Binding var selected: String

    var options: [String]

    var body: some View {
        ForEach(options, id: \.self) {option in
            Button {
                selected = option
            } label: {
                HStack{
                    let isSelected = option == selected
                    let radioImg = isSelected ? "circle.inset.filled" : "circle"
                    Image(systemName: radioImg)
                        .foregroundColor(isSelected ? Color.black : Color.gray)
                    Text(t.t(option))
                        .foregroundColor(Color.black)

                }
            }
        }
    }
}
