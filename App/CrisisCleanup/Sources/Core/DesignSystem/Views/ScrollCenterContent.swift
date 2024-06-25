import SwiftUI

struct ScrollCenterContent<Content>: View where Content: View {
    private let maxWidth: CGFloat?
    private let contentAlignment: HorizontalAlignment
    private let contentPadding: Edge.Set?
    private let content: Content

    init(
        maxWidth: CGFloat? = 600.0,
        contentAlignment: HorizontalAlignment = .leading,
        contentPadding: Edge.Set? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.contentAlignment = contentAlignment
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                VStack(alignment: contentAlignment) {
                    content
                }
                .if (contentPadding != nil) {
                    $0.padding(contentPadding!)
                }
                .frame(maxWidth: maxWidth)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
