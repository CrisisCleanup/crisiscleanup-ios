import Foundation

class CountTimeTracker {
    private var counts = [CountTime]()

    func time<T>(_ operation: @escaping () async throws -> [T]) async throws -> [T] {
        let startDownloadTime = Date.now
        let result = try await operation()
        let endDownloadTime = Date.now
        let downloadSeconds = startDownloadTime.distance(to: endDownloadTime).seconds
        onCountTime(result.count, downloadSeconds)
        return result
    }

    private func onCountTime(_ count: Int, _ timeSeconds: Double) {
        counts.append(
            CountTime(
                count: count,
                timeSeconds: timeSeconds,
            ),
        )
    }

    func averageSpeed() -> Double? {
        let countSnapshot = counts.count
        var totalCount = 0
        var totalSeconds = 0.0
        var zeroCounts = 0
        var counted = 0
        for i in 0..<countSnapshot {
            with(counts[i]) { countTime in
                if countTime.count == 0 || countTime.timeSeconds <= 0 {
                    zeroCounts += 1
                } else {
                    totalCount += countTime.count
                    totalSeconds += countTime.timeSeconds

                    counted += 1
                }
            }
            if counted >= 3 {
                break
            }
        }
        return if zeroCounts > counted || totalSeconds <= 0 {
            if zeroCounts == 1 {
                nil
            } else {
                0.0
            }
        } else {
            Double(totalCount) / totalSeconds
        }
    }
}

private struct CountTime {
    let count: Int
    let timeSeconds: Double
}
