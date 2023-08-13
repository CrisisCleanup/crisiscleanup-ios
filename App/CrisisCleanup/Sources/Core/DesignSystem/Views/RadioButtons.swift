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
    @State var tempValue = 1

    var body: some View {
        HStack {
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

            if(text == "t.treccurringSchedule") {
                Stepper(value: $tempValue,
                        in: 1...99,
                        step: 1) {
                    HStack {
                        Text(tempValue.description)
                            .frame(width: 30, height: 30)
                            .padding()
                            .background(appTheme.colors.attentionBackgroundColor)
                            .cornerRadius(appTheme.cornerRadius)
                    }
                }
                        .tint(.black)
            }
        }
    }
}
