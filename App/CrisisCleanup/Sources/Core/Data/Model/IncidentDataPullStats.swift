import Foundation

enum IncidentPullDataType {
    case worksitesCore,
         worksitesAdditional,
         organizations
}

private let worksiteDataPullTypes = Set([
    IncidentPullDataType.worksitesCore,
    IncidentPullDataType.worksitesAdditional
])

// sourcery: copyBuilder, skipCopyInit
public struct IncidentDataPullStats {
    let incidentId: Int64
    let incidentName: String
    let pullType: IncidentPullDataType
    let isIndeterminate: Bool
    let stepTotal: Int
    let currentStep: Int
    let notificationMessage: String

    let isStarted: Bool
    let startTime: Date
    let isEnded: Bool

    let dataCount: Int
    let queryCount: Int
    let savedCount: Int

    internal let startProgressAmount: Double

    // sourcery:begin: skipCopy
    let isOngoing: Bool
    let isPullingWorksites: Bool
    let progress: Double
    // sourcery:end

    init(
        incidentId: Int64 = EmptyIncident.id,
        incidentName: String = EmptyIncident.shortName,
        pullType: IncidentPullDataType = .worksitesCore,
        isIndeterminate: Bool = false,
        stepTotal: Int = 0,
        currentStep: Int = 0,
        notificationMessage: String = "",
        isStarted: Bool = false,
        startTime: Date = Date.now,
        isEnded: Bool = false,
        dataCount: Int = 0,
        queryCount: Int = 0,
        savedCount: Int = 0,
        startProgressAmount: Double = 0.001
    ) {
        self.incidentId = incidentId
        self.incidentName = incidentName
        self.pullType = pullType
        self.isIndeterminate = isIndeterminate
        self.stepTotal = stepTotal
        self.currentStep = currentStep
        self.notificationMessage = notificationMessage
        self.isStarted = isStarted
        self.startTime = startTime
        self.isEnded = isEnded
        self.dataCount = dataCount
        self.queryCount = queryCount
        self.savedCount = savedCount
        self.startProgressAmount = startProgressAmount

        isOngoing = isStarted && !isEnded

        isPullingWorksites = worksiteDataPullTypes.contains(pullType)

        progress = {
            if !isStarted {
                return 0
            }

            if isEnded {
                return 1
            }

            if isIndeterminate {
                return 0.5
            }

            return if dataCount > 0 {
                min(0.999, max(0, Double(queryCount + savedCount) / Double(2 * dataCount)))
            } else {
                startProgressAmount
            }
        }()
    }
}
