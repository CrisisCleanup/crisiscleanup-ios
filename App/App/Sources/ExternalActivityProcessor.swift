import CrisisCleanup
import Foundation

class ExternalActivityProcessor {
    private let externalEventBus: ExternalEventBus

    init(externalEventBus: ExternalEventBus) {
        self.externalEventBus = externalEventBus
    }

    func process(_ components: NSURLComponents) -> Bool {
        // Check for specific URL components that you need.
        guard let path = components.path else {
            return false
        }

        if path.starts(with: "/o/callback") {
            guard let params = components.queryItems,
                  let code = params.first(where: { $0.name == "code" } )?.value else {
                return false
            }

            externalEventBus.onEmailLoginLink(code)
            return true

        } else if path.starts(with: "/password/reset") {
            let code = path.replacingOccurrences(of: "/password/reset/", with: "")
            if code.isNotBlank {
                externalEventBus.onResetPassword(code)
                return true
            }
        }

        return false
    }
}
