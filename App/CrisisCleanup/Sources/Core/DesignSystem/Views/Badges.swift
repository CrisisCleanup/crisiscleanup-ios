import SwiftUI

func filterBadge(_ count: Int) -> some View {
    Text(String(count))
        .fontBodySmall()
        .padding(.all, 6)
        .background(appTheme.colors.themePrimaryContainer)
        .clipShape(Circle())
    // TODO: Offset based on view size
        .offset(x: 8, y: -8)
}
