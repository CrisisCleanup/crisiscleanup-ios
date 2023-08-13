import SwiftUI

struct LargeTextEditor: View {
    @EnvironmentObject var focusableViewState: TextInputFocusableView

    @Binding var text: String

    var focusedKey: TextInputFocused = .anyTextInput

    @FocusState private var focusState: TextInputFocused?

    var body: some View {
        TextEditor(text: $text)
            .focused($focusState, equals: focusedKey)
            .onChange(of: focusState) { focusableViewState.focusState = $0 }
            .frame(height: appTheme.rowItemHeight*2)
            .lineLimit(5)
            .textFieldBorder()
            .tint(.black)
    }
}
