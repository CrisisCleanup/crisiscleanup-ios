import SwiftUI

struct ScrollCenterContent<Content>: View where Content: View {
    private let contentAlignment: HorizontalAlignment
    private let contentPadding: Edge.Set?
    private let content: Content

    init(
        contentAlignment: HorizontalAlignment = .leading,
        contentPadding: Edge.Set? = nil,
        @ViewBuilder content: () -> Content
    ) {
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
                .frame(maxWidth: appTheme.contentMaxWidth)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
