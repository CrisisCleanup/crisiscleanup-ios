import SwiftUI

struct FormListSectionSeparator: View {
    var body: some View {
        Divider()
        // TODO: Common dimensions
            .frame(height: 32)
            .overlay(appTheme.colors.separatorColor)
    }
}
