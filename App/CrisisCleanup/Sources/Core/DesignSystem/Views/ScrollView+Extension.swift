import SwiftUI

struct WrappingHeightScrollView<Content>: View where Content: View {
    @State private var contentHeight: CGFloat = .zero

    let scrollDismissMode: ScrollDismissesKeyboardMode
    let content: Content

    init(
        scrollDismissMode: ScrollDismissesKeyboardMode = .immediately,
        @ViewBuilder content: () -> Content
    ) {
        self.scrollDismissMode = scrollDismissMode
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .viewHeightObserver(contentHeight: $contentHeight)
        }
        .scrollDismissesKeyboard(scrollDismissMode)
        .frame(maxHeight: contentHeight)
    }
}
