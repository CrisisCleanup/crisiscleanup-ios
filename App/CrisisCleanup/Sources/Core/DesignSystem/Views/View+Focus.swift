import Combine
import SwiftUI

enum TextInputFocused: Hashable {
    case anyTextInput,
         querySuggestionsInput
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
                self.isQueryInputFocused = $0 == .querySuggestionsInput
            })
            .store(in: &disposables)
    }

    func clear() {
        focusState = nil
    }
}
