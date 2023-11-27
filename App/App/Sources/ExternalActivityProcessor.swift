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
            let params = components.queryItems
            if let inviterIdString = params?.find("user-id"),
               let inviterId = Int64(inviterIdString),
               let token = params?.find("invite-token") {
                externalEventBus.onOrgPersistentInvite(inviterId, token)
            } else {
                return false
            }
        }

        return false
    }
}

fileprivate extension [URLQueryItem] {
    func find(_ name: String) -> String? {
        first(where: { $0.name == name })?.value
    }
}
