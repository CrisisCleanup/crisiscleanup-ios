import SwiftUI

extension View {
    @inlinable func horizontalVerticalPadding(_ horizontal: Double, _ vertical: Double) -> some View {
        self.padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
    }

    func cardContainer(background: Color = .white) -> some View {
        self.background(background)
            .cornerRadius(appTheme.cornerRadius)
            .shadow(radius: appTheme.shadowRadius)
    }

    func cardContainerPadded() -> some View {
        self.cardContainer()
            .padding()
    }

    // https://www.avanderlee.com/swiftui/conditional-view-modifier/
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }

    func blackBorder() -> some View {
        // TODO: Change text and border color based on state (disabled, selected, ...). Create style instead?
        self
            .cornerRadius(appTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: appTheme.cornerRadius)
                    .stroke(.black, lineWidth: appTheme.textFieldOutlineWidth)
            )
    }

#if canImport(UIKit)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
#endif
}

class EditableView: ObservableObject {
    @Published var isEditable: Bool = false
    var disabled: Bool { !isEditable }
}
