import SwiftUI

struct LargeTextEditor: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .frame(height: appTheme.rowItemHeight*2)
            .lineLimit(5)
            .textFieldBorder()
            .tint(.black)
    }
}
