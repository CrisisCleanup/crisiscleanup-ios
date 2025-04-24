import Combine
import Foundation

public protocol IncidentDataPullReporter {
    var incidentDataPullStats: any Publisher<IncidentDataPullStats, Never> { get }
    var onIncidentDataPullComplete: any Publisher<Int64, Never> { get }
}

// sourcery: copyBuilder, skipCopyInit
public struct IncidentDataPullStats {
    let incidentId: Int64
    // TODO: Update properties and source Builder

    let isStarted: Bool
    let pullStart: Date

    let dataCount: Int
    let isPagingRequest: Bool
    let requestedCount: Int
    let savedCount: Int
    let isEnded: Bool
    internal let startProgressAmount: Double
    internal let countProgressAmount: Double
    internal let requestStartedAmount: Double
    let saveStartedAmount: Double

    // sourcery:begin: skipCopy
    let isOngoing: Bool
    let progress: Double
    let projectedFinish: Date
    // sourcery:end

    init(
        isStarted: Bool = false,
        incidentId: Int64 = EmptyIncident.id,
        pullStart: Date = Date.now,
        dataCount: Int = 0,
        isPagingRequest: Bool = false,
        requestedCount: Int = 0,
        savedCount: Int = 0,
        isEnded: Bool = false,
        startProgressAmount: Double = 0.01,
        countProgressAmount: Double = 0.05,
        requestStartedAmount: Double = 0.01,
        saveStartedAmount: Double = 0.33
    ) {
        self.isStarted = isStarted
        self.incidentId = incidentId
        self.pullStart = pullStart
        self.dataCount = dataCount
        self.isPagingRequest = isPagingRequest
        self.requestedCount = requestedCount
        self.savedCount = savedCount
        self.isEnded = isEnded
        self.startProgressAmount = startProgressAmount
        self.countProgressAmount = countProgressAmount
        self.requestStartedAmount = requestStartedAmount
        self.saveStartedAmount = saveStartedAmount

        isOngoing = isStarted && !isEnded

        let progressComputed = {
            var progress = 0.0
            if isStarted {
                // Pull has started
                progress = startProgressAmount
                if dataCount > 0 {
                    progress = countProgressAmount

                    let remainingProgress = {
                        if isPagingRequest {
                            return Double(requestedCount + savedCount) * 0.5 / Double(dataCount)
                        } else {
                            if savedCount > 0 {
                                let num = (1.0 - saveStartedAmount) * Double(savedCount)
                                let den = Double(requestedCount)
                                let value = saveStartedAmount + num / den
                                return Double(value)
                            } else if requestedCount > 0 {
                                return Double(saveStartedAmount)
                            } else {
                                return Double(requestStartedAmount)
                            }
                        }
                    }()

                    progress += (1 - progress) * remainingProgress
                }
            }
            return min(progress, 1.0)
        }()
        let projectedFinishComputed = {
            let now = Date.now
            let deltaSeconds = now.timeIntervalSince1970 - pullStart.timeIntervalSince1970
            let p = progressComputed
            if p <= 0 || deltaSeconds <= 0 {
                return now.addingTimeInterval(999_999.hours)
            }

            let projectedDeltaSeconds = (deltaSeconds / p).rounded()
            return pullStart.addingTimeInterval(projectedDeltaSeconds)
        }()

        progress = progressComputed
        projectedFinish = projectedFinishComputed
    }
}

internal class IncidentDataPullStatsUpdater {
    private var pullStats: IncidentDataPullStats
    private let updatePullStats: (IncidentDataPullStats) -> Void

    init(
        _ updatePullStats: @escaping (IncidentDataPullStats) -> Void,
        _ pullStats: IncidentDataPullStats = IncidentDataPullStats()
    ) {
        self.pullStats = pullStats
        self.updatePullStats = updatePullStats
    }

    private func reportChange(_ pullStats: IncidentDataPullStats) {
        self.pullStats = pullStats
        updatePullStats(pullStats)
    }

    func beginPull(_ incidentId: Int64) {
        reportChange(
            pullStats.copy {
                $0.isStarted = true
                $0.incidentId = incidentId
                $0.pullStart = Date.now
            }
        )
    }

    func setPagingRequest() {
        reportChange(pullStats.copy { $0.isPagingRequest = true })
    }

    func updateDataCount(_ dataCount: Int) {
        reportChange(pullStats.copy { $0.dataCount = dataCount })
    }

    func updateRequestedCount(_ requestedCount: Int) {
        reportChange(pullStats.copy { $0.requestedCount = requestedCount })
    }

    func addSavedCount(_ savedCount: Int) {
        reportChange(pullStats.copy { $0.savedCount = pullStats.savedCount + savedCount })
    }

    func endPull() {
        reportChange(pullStats.copy { $0.isEnded = true })
    }
}
