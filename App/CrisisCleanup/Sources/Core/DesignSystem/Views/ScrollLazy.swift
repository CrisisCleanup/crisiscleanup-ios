import SwiftUI

struct ScrollLazyVGrid<Content>: View where Content: View {
    let columns: [GridItem]
    var content: Content

    init(
        columns: [GridItem] = [GridItem(.flexible())],
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.content = content()
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                content
            }
        }
    }
}
