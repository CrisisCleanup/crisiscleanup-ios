import SwiftUI

extension View {
    @inlinable func horizontalVerticalPadding(_ horizontal: Double, _ vertical: Double) -> some View {
        self.padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
    }

    func cardContainer() -> some View {
        self.background(.white)
            .cornerRadius(appTheme.cornerRadius)
            .shadow(radius: appTheme.shadowRadius)
    }

    func cardContainerPadded() -> some View {
        self.cardContainer()
            .padding()
    }
}
