import SwiftUI

struct OpenKeyboardActionsView: View {
    @EnvironmentObject var viewLayout: ViewLayoutDescription

    var body: some View {
        if viewLayout.isShort || !viewLayout.isWide {
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
}

extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
