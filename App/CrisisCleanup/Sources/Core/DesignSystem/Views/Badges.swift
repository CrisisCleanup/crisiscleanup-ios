import SwiftUI

func filterBadge(_ count: Int) -> some View {
    Text("\(count)")
        .fontBodySmall()
        .padding(.all, 4)
        .background(appTheme.colors.themePrimaryContainer)
        .clipShape(Circle())
    // TODO: Offset based on text size
        .offset(x: 8, y: -8)
}
