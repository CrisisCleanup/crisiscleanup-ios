import SwiftUI

struct SuggestionsSearchField: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var focusableViewState: TextInputFocusableView

    @Binding var q: String
    @Binding var animateSearchFieldFocus: Bool
    @FocusState var focusState: TextInputFocused?
    var focusedKey: TextInputFocused? = .querySuggestions

    let hint: String
    var disableAutocorrect = false

    var onClose: () -> Void = {}

    var body: some View {
        HStack {
            TextField(hint, text: $q)
                .autocorrectionDisabled(disableAutocorrect)
                .focused($focusState, equals: focusedKey)
                .onChange(of: focusState) { isFocused in
                    withAnimation(.easeInOut(duration: appTheme.layoutAnimationDuration)) {
                        animateSearchFieldFocus = isFocused == focusedKey
                    }
                }
                .textFieldBorder()

            if animateSearchFieldFocus {
                Button {
                    focusState = nil
                    animateSearchFieldFocus = false
                    onClose()
                } label: {
                    Text(t.t("actions.close"))
                }
                .padding(.leading, appTheme.gridItemSpacing)
            }
        }
    }
}
