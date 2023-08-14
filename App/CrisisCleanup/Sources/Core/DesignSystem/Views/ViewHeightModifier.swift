import SwiftUI

struct ViewHeightModifier: ViewModifier {
    @Binding var contentHeight: CGFloat

    func body(content: Content) -> some View {
        return content
            .overlay(GeometryReader {
                Color.clear.preference(key: FloatPreferenceKey.self, value: $0.size.height)
            })
            .onPreferenceChange(FloatPreferenceKey.self) { height in
                contentHeight = height
            }
    }
}

extension View {
    func viewHeightObserver(contentHeight: Binding<CGFloat>) -> some View {
        ModifiedContent(content: self, modifier: ViewHeightModifier(contentHeight: contentHeight))
    }
}
