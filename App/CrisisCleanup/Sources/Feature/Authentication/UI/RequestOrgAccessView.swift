import SwiftUI

struct RequestOrgAccessView: View {
    @State var languageOptions = [
        "languages.en-us",
        "languages.es-mx",
    ]

    @State var userInfo = UserInfoInputData()

    @FocusState private var focusState: TextInputFocused?

    var body: some View {
        ScrollView {
            UserInfoInputView(
                languageOptions: $languageOptions,
                info: $userInfo,
                focusState: $focusState
            )
            .padding(.horizontal)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}
