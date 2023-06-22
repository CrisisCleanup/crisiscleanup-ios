import SwiftUI

let statusUnknownColorCode: Int64 = 0xFF000000
let statusUnclaimedColorCode: Int64 = 0xFFD0021B
let statusNotStartedColorCode: Int64 = 0xFFFAB92E
let statusInProgressColorCode: Int64 = 0xFFF0F032
let statusPartiallyCompletedColorCode: Int64 = 0xFF0054BB
let statusNeedsFollowUpColorCode: Int64 = 0xFFEA51EB
let statusCompletedColorCode: Int64 = 0xFF0fa355
let statusDoneByOthersNhwColorCode: Int64 = 0xFF82D78C
let statusOutOfScopeRejectedColorCode: Int64 = 0xFF1D1D1D
let statusUnresponsiveColorCode: Int64 = 0xFF787878
let statusDuplicateUnclaimedColorCode: Int64 = 0xFF7F7F7F
let statusDuplicateClaimedColorCode: Int64 = 0xFF82D78C
let statusUnknownColor = Color(hex: statusUnknownColorCode)
let statusUnclaimedColor = Color(hex: statusUnclaimedColorCode)
let statusNotStartedColor = Color(hex: statusNotStartedColorCode)
let statusInProgressColor = Color(hex: statusInProgressColorCode)
let statusPartiallyCompletedColor = Color(hex: statusPartiallyCompletedColorCode)
let statusNeedsFollowUpColor = Color(hex: statusNeedsFollowUpColorCode)
let statusCompletedColor = Color(hex: statusCompletedColorCode)
let statusDoneByOthersNhwDiColor = Color(hex: statusDoneByOthersNhwColorCode)
let statusOutOfScopeRejectedColor = Color(hex: statusOutOfScopeRejectedColorCode)
let statusUnresponsiveColor = Color(hex: statusUnresponsiveColorCode)

struct MapMarkerColor {
    private let fillLong: Int64
    private let strokeLong: Int64
    let fillInt: Int
    let strokeInt: Int
    let fill: Color
    let stroke: Color

    init(
        _ fillLong: Int64,
        _ strokeLong: Int64 = 0xFFFFFFFF
    ) {
        self.fillLong = fillLong
        self.strokeLong = strokeLong
        self.fillInt = Int(fillLong)
        self.strokeInt = Int(strokeLong)
        self.fill = Color(hex: fillLong)
        self.stroke = Color(hex: strokeLong)
    }
}

private let statusMapMarkerColors: [CaseStatus: MapMarkerColor] = [
    .unknown: MapMarkerColor(statusUnknownColorCode),
    .unclaimed: MapMarkerColor(statusUnclaimedColorCode),
    .claimedNotStarted: MapMarkerColor(statusNotStartedColorCode),
    // Assigned
    .inProgress: MapMarkerColor(statusInProgressColorCode),
    .partiallyCompleted: MapMarkerColor(statusPartiallyCompletedColorCode),
    .needsFollowUp: MapMarkerColor(statusNeedsFollowUpColorCode),
    .completed: MapMarkerColor(statusCompletedColorCode),
    .doneByOthersNhwPc: MapMarkerColor(statusDoneByOthersNhwColorCode),
    // Unresponsive
    .outOfScopeDu: MapMarkerColor(statusOutOfScopeRejectedColorCode),
    .incomplete: MapMarkerColor(statusDoneByOthersNhwColorCode),
]

private let statusClaimMapMarkerColors: [WorkTypeStatusClaim: MapMarkerColor] = [
    WorkTypeStatusClaim(.closedDuplicate, true): MapMarkerColor(statusDuplicateClaimedColorCode),
    WorkTypeStatusClaim(.openPartiallyCompleted, false): MapMarkerColor(statusUnclaimedColorCode),
    WorkTypeStatusClaim(.openNeedsFollowUp, false): MapMarkerColor(statusUnclaimedColorCode),
    WorkTypeStatusClaim(.closedDuplicate, false): MapMarkerColor(statusDuplicateUnclaimedColorCode),
]

internal func getMapMarkerColors(statusClaim: WorkTypeStatusClaim) -> MapMarkerColor {
    var colors = statusClaimMapMarkerColors[statusClaim]
    if colors == nil {
        if let status = statusClaimToStatus[statusClaim] {
            colors = statusMapMarkerColors[status]
        }
    }
    return colors ?? statusMapMarkerColors[.unknown]!
}
