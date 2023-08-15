import SwiftUI

struct ScrollLazyVGrid<Content>: View where Content: View {
    let columns: [GridItem]
    let gridItemSpacing: CGFloat
    var content: Content

    init(
        columns: [GridItem] = [GridItem(.flexible())],
        gridItemSpacing: CGFloat = .zero,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.gridItemSpacing = gridItemSpacing
        self.content = content()
    }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: columns,
                spacing: gridItemSpacing
            ) {
                content
            }
        }
    }
}
