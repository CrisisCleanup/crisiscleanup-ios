import SwiftUI

struct CheckboxViews: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var selectedOptions: [String]
    var options: [(String, String)]

    var body: some View {
        ForEach(options, id: \.0) { (key, label) in
            Button {
                if selectedOptions.contains(key) {
                    selectedOptions.remove(at: selectedOptions.firstIndex(of: key)!)
                } else {
                    selectedOptions.append(key)
                }
            } label: {
                HStack{
                    let isSelected = selectedOptions.contains(key)
                    let checkImg = isSelected ? "checkmark.square.fill" : "square"
                    Image(systemName: checkImg)
                        .foregroundColor(isSelected ? Color.black : Color.gray)
                    Text(label)
                        .foregroundColor(Color.black)
                }
            }
            .padding(.vertical)
        }
    }
}

struct CheckboxView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var checked: Bool
    let text: String

    var body: some View {
        Button {
            checked.toggle()
        } label: {
            HStack{
                let checkImg = checked ? "checkmark.square.fill" : "square"
                Image(systemName: checkImg)
                    .foregroundColor(checked ? Color.black : Color.gray)
                Text(text)
                    .foregroundColor(Color.black)
            }
        }
        .padding(.vertical)
    }
}
