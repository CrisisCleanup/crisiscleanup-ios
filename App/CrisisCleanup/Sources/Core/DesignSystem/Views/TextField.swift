import SwiftUI

extension View {
    func textFieldBorder() -> some View {
        // TODO: Change text and border color based on state (disabled, selected, ...). Create style instead?
        return self
            .padding(appTheme.textFieldInnerPadding)
            .cornerRadius(appTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: appTheme.cornerRadius)
                    .stroke(.gray, lineWidth: appTheme.textFieldOutlineWidth)
            )
    }
}

struct ToggleSecureTextField: View {
    @Binding private var text: String
    @State private var isSecure: Bool = true
    private var title: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                } else {
                    TextField(title, text: $text)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                }
            }
            .padding(.trailing, 32)

            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: self.isSecure ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
        }
        .textFieldBorder()
    }
}
