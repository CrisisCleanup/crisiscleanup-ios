import CrisisCleanup
import Foundation

class ExternalActivityProcessor {
    private let externalEventBus: ExternalEventBus

    init(externalEventBus: ExternalEventBus) {
        self.externalEventBus = externalEventBus
    }

    private func getTrailingPath(path: String, prefix: String) -> String? {
        path.starts(with: prefix) ? path.replacingOccurrences(of: prefix, with: "") : nil
    }

    func process(_ components: NSURLComponents) -> Bool {
        guard let path = components.path else {
            return false
        }

        if let code = getTrailingPath(path: path, prefix: "/l/"),
           code.isNotBlank {
            externalEventBus.onEmailLoginLink(code)
            return true

        } else if let code = getTrailingPath(path: path, prefix: "/password/reset/"),
                  code.isNotBlank {
            externalEventBus.onResetPassword(code)
            return true

        } else if let code = getTrailingPath(path: path, prefix: "/invitation_token/"),
                  code.isNotBlank {
            externalEventBus.onOrgUserInvite(code)
            return true

        } else if path.starts(with: "/mobile_app_user_invite") {
            if let query = components.queryItems {
                return externalEventBus.onOrgPersistentInvite(query)
            }
            return false
        }

        return false
    }
}
