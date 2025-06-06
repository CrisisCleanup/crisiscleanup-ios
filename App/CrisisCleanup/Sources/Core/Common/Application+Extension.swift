import SwiftUI

extension UIApplication {
    func checkTimeout(_ minRemainingTime: TimeInterval) throws -> TimeInterval? {
        let appState = applicationState
        if appState == .background {
            let backgroundTime = backgroundTimeRemaining
            if backgroundTime < minRemainingTime {
                throw CancellationError()
            } else {
                return backgroundTime
            }
        }

        return nil
    }
}
