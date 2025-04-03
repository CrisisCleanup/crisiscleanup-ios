import SwiftUI

struct StackActionsView<Content>: View where Content : View {
    var isVertical = false

    @ViewBuilder let content: () -> Content

    var body: some View {
        if isVertical {
            VStack(spacing: appTheme.gridActionSpacing) {
                Spacer()

                content()
            }
            .padding([.horizontal, .bottom], appTheme.edgeSpacing)
        } else {
            HStack {
                content()
            }
            .padding([.horizontal, .bottom], appTheme.gridItemSpacing)
        }
    }
}
