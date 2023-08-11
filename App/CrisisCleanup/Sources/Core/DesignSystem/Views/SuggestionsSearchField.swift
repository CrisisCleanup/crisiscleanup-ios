import SwiftUI

struct SuggestionsSearchField: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var q: String
    @Binding var animateSearchFieldFocus: Bool
    @FocusState var isQueryFocused

    let hint: String

    var body: some View {
        HStack {
            TextField(hint, text: $q)
                .focused($isQueryFocused)
                .onChange(of: isQueryFocused) { isFocused in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animateSearchFieldFocus = isFocused
                    }
                }
                .textFieldBorder()

            if animateSearchFieldFocus {
                Button {
                    isQueryFocused = false
                } label: {
                    Text(t.t("actions.close"))
                }
                // TODO: Common dimensions
                .padding(.leading, 8)
            }
        }
    }
}
