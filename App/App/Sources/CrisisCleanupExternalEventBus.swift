import Combine
import CrisisCleanup

class CrisisCleanupExternalEventBus: ExternalEventBus {
    private let emailLoginLinksSubject = PassthroughSubject<String, Never>()
    let emailLoginLinks: any Publisher<String, Never>

    private let resetPasswordsSubject = PassthroughSubject<String, Never>()
    let resetPasswords: any Publisher<String, Never>

    init() {
        emailLoginLinks = emailLoginLinksSubject.share()
        resetPasswords = resetPasswordsSubject.share()
    }

    func onEmailLoginLink(_ code: String) {
        emailLoginLinksSubject.send(code)
    }

    func onResetPassword(_ code: String) {
        resetPasswordsSubject.send(code)
    }
}
