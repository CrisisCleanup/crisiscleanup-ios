import Foundation

// TODO: Copy tests
// sourcery: copyBuilder
struct SyncAttempt: Codable {
    let successfulSeconds: Double
    let attemptedSeconds: Double
    let attemptedCounter: Int

    init(successfulSeconds: Double = 0.0,
         attemptedSeconds: Double = 0.0,
         attemptedCounter: Int = 0
    ) {
        self.successfulSeconds = successfulSeconds
        self.attemptedSeconds = attemptedSeconds
        self.attemptedCounter = attemptedCounter
    }

    func isRecent(
        _ recentIntervalSeconds: Double = 1800,
        _ nowSeconds: Double = Date.now.timeIntervalSince1970
    ) -> Bool {
        return nowSeconds - successfulSeconds < recentIntervalSeconds
    }

    func isBackingOff(
        _ backoffIntervalSeconds: Double = 15,
        _ nowSeconds: Double = Date.now.timeIntervalSince1970
    ) -> Bool {
        if attemptedCounter < 1 {
            return false
        }

        let deltaSeconds = max(nowSeconds - attemptedSeconds, 1)
        if deltaSeconds > 3600 {
            return false
        }

        let intervalSeconds = max(backoffIntervalSeconds, 1)
        // now < attempted + interval * 2^(tries-1)
        let lhs = log2(deltaSeconds / intervalSeconds)
        let rhs = Double(attemptedCounter - 1) * log2(2.0)
        return lhs < rhs
    }

    func shouldSyncPassively(
        recentIntervalSeconds: Double = 1800,
        backoffIntervalSeconds: Double = 15,
        nowSeconds: Double = Date.now.timeIntervalSince1970
    ) -> Bool {
        !(isRecent(recentIntervalSeconds, nowSeconds) ||
          isBackingOff(backoffIntervalSeconds, nowSeconds))
    }
}
