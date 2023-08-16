import SwiftUI

struct FormListSectionSeparator: View {
    var body: some View {
        Divider()
            .frame(height: 32)
            .overlay(appTheme.colors.separatorColor)
    }
}
