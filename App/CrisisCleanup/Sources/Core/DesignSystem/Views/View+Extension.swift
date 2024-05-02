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
    @ViewBuilder func `if`<Content: View>(
        _ condition: @autoclosure () -> Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }

    func roundedCorners(_ color: Color = .black) -> some View {
        self.cornerRadius(appTheme.cornerRadius)
            .roundedBorder(color: color)
    }

#if canImport(UIKit)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
#endif

    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}

class EditableView: ObservableObject {
    @Published var isEditable: Bool = false
    var disabled: Bool { !isEditable }
}
