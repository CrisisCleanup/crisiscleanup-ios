import SwiftUI

extension View {
    func textFieldBorder() -> some View {
        // TODO: Change text and border color based on state (disabled, selected, ...). Create style instead?
        self
            .padding(appTheme.textFieldInnerPadding)
            .cornerRadius(appTheme.cornerRadius)
            .roundedBorder()
    }
}

struct ToggleSecureTextField: View {
    @Binding private var text: String
    @State private var isSecure: Bool = true
    private var title: String

    private let focusedKey: TextInputFocused
    private var focusState: FocusState<TextInputFocused?>.Binding

    init(
        _ title: String,
        text: Binding<String>,
        focusState: FocusState<TextInputFocused?>.Binding,
        focusedKey: TextInputFocused = .anyTextInput
    ) {
        self.title = title
        self._text = text
        self.focusState = focusState
        self.focusedKey = focusedKey
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused(focusState, equals: focusedKey)
                } else {
                    TextField(title, text: $text)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused(focusState, equals: focusedKey)
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
