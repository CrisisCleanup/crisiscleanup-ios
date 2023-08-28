import SwiftUI

struct CheckboxViews: View {
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
                let isSelected = selectedOptions.contains(key)
                CheckboxTextView(isChecked: isSelected, text: label)
            }
            .padding(.vertical)
        }
    }
}

struct CheckboxTextView : View {
    @Environment(\.isEnabled) var isEnabled

    let isChecked: Bool
    let text: String

    var nestedLevel: Int? = nil
    var isListItem: Bool = false

    var body: some View {
        HStack{
            let checkImg = isChecked ? "checkmark.square.fill" : "square"
            Image(systemName: checkImg)
                .foregroundColor(isChecked && isEnabled ? Color.black : Color.gray)
                .if(nestedLevel != nil) {
                    $0.padding(.leading, Double(nestedLevel!) * appTheme.nestedItemPadding)
                }
            Text(text)
                .foregroundColor(Color.black)
                .multilineTextAlignment(.leading)
        }
        .if(isListItem) {
            $0.listItemModifier()
        }
    }
}

struct CheckboxView: View {
    @Binding var checked: Bool
    let text: String

    var nestedLevel: Int? = nil
    var isListItem: Bool = false

    var body: some View {
        Button {
            checked.toggle()
        } label: {
            CheckboxTextView(
                isChecked: checked,
                text: text,
                nestedLevel: nestedLevel,
                isListItem: isListItem
            )
        }
        .if(!isListItem) {
            $0.padding(.vertical)
        }
    }
}

struct StatelessCheckboxView: View {
    let checked: Bool
    let text: String
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            CheckboxTextView(isChecked: checked, text: text)
        }
        .padding(.vertical)
    }
}
