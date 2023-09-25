import Combine
import SwiftUI

class PasswordRecoverViewModel: ObservableObject {
    let showForgotPassword: Bool
    let showMagicLink: Bool

    init(
        showForgotPassword: Bool,
        showMagicLink: Bool
    ) {
        self.showForgotPassword = showForgotPassword
        self.showMagicLink = showMagicLink
    }
}
