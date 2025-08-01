import Combine
import SwiftUI

enum TextInputFocused: Hashable {
    case anyTextInput,
         querySuggestions,
         authEmailAddress,
         authPassword,
         authConfirmPassword,
         authPhone,
         userEmailAddress,
         userFirstName,
         userLastName,
         userTitle,
         userPhone,
         userPassword,
         userConfirmPassword,
         caseInfoName,
         caseInfoPhone,
         caseInfoPhoneNotes,
         caseInfoPhone2,
         caseInfoPhone2Notes,
         caseInfoEmail,
         caseInfoStreetAddress,
         caseInfoZipCode,
         caseInfoCity,
         caseInfoCounty,
         caseInfoState,
         caseInfoCrossStreet
}

class TextInputFocusableView: ObservableObject {
    @Published var focusState: TextInputFocused?
    @Published private(set) var isFocused: Bool = false
    @Published private(set) var isNotFocused: Bool = true
    @Published private(set) var isQueryInputFocused: Bool = false

    private var disposables = Set<AnyCancellable>()

    init() {
        $focusState
            .sink(receiveValue: {
                self.isFocused = $0 != nil
                self.isNotFocused = $0 == nil
                self.isQueryInputFocused = $0 == .querySuggestions
            })
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    func clear() {
        focusState = nil
    }
}
