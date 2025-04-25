import Combine
import Foundation

public protocol IncidentDataPullReporter {
    var incidentDataPullStats: any Publisher<IncidentDataPullStats, Never> { get }
    var onIncidentDataPullComplete: any Publisher<Int64, Never> { get }
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

    func beginPull(
        _ incidentId: Int64,
        _ incidentName: String,
        _ pullType: IncidentPullDataType,
        _ startTime: Date = Date.now
    ) {
        reportChange(
            pullStats.copy {
                $0.incidentId = incidentId
                $0.incidentName = incidentName
                $0.pullType = pullType
                $0.isStarted = true
                $0.startTime = startTime
            }
        )
    }

    func setIndeterminate() {
        reportChange(pullStats.copy { $0.isIndeterminate = true })
    }

    func setDeterminate() {
        reportChange(pullStats.copy { $0.isIndeterminate = false })
    }

    func setDataCount(_ count: Int) {
        reportChange(pullStats.copy { $0.dataCount = count })
    }

    func addDataCount(_ count: Int) {
        reportChange(pullStats.copy { $0.dataCount = $0.dataCount + count })
    }

    func addQueryCount(_ count: Int) {
        reportChange(pullStats.copy { $0.queryCount = $0.queryCount + count })
    }

    func addSavedCount(_ savedCount: Int) {
        reportChange(pullStats.copy { $0.savedCount = pullStats.savedCount + savedCount })
    }

    func setStep(current: Int, total: Int) {
        reportChange(
            pullStats.copy {
                $0.currentStep = current
                $0.stepTotal = total
            }
        )
    }

    func clearStep() {
        setStep(current: 0, total: 0)
    }

    func setNotificationMessage(_ message: String = "") {
        reportChange(pullStats.copy { $0.notificationMessage = message })
    }

    func clearNotificationMessage() {
        setNotificationMessage()
    }
}
