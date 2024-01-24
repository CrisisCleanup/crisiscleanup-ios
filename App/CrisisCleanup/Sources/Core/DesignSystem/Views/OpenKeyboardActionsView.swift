import SwiftUI

struct OpenKeyboardActionsView: View {
    var body: some View {
        HStack {
            Spacer()
            Button {
                hideKeyboard()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down.fill")
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }
}

extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
