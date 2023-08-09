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

private struct CheckboxTextView : View {
    let isChecked: Bool
    let text: String

    var body: some View {
        HStack{
            let checkImg = isChecked ? "checkmark.square.fill" : "square"
            Image(systemName: checkImg)
                .foregroundColor(isChecked ? Color.black : Color.gray)
            Text(text)
                .foregroundColor(Color.black)
                .multilineTextAlignment(.leading)
        }
    }
}

struct CheckboxView: View {
    @Binding var checked: Bool
    let text: String

    var body: some View {
        Button {
            checked.toggle()
        } label: {
            CheckboxTextView(isChecked: checked, text: text)
        }
        .padding(.vertical)
    }
}

struct CheckboxChangeView: View {
    @State var checked: Bool
    let text: String
    var onCheckChange: (Bool) -> Void = {_ in}

    var body: some View {
        Button {
            checked.toggle()
            onCheckChange(checked)
        } label: {
            CheckboxTextView(isChecked: checked, text: text)
        }
        .padding(.vertical)
    }
}
