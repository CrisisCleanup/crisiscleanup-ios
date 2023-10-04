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

let statusClosedColor = Color(hex: statusDuplicateClaimedColorCode)

private let visitedMarkerColorCode: Int64 = 0xFF681da8

// sourcery: copyBuilder
struct MapMarkerColor {
    let fillInt64: Int64
    let strokeInt64: Int64
    let fillInt: Int
    let strokeInt: Int
    let fill: Color
    let stroke: Color

    init(
        _ fillInt64: Int64,
        _ strokeInt64: Int64 = 0xFFFFFFFF
    ) {
        self.fillInt64 = fillInt64
        self.strokeInt64 = strokeInt64
        self.fillInt = Int(fillInt64)
        self.strokeInt = Int(strokeInt64)
        self.fill = Color(hex: fillInt64)
        self.stroke = Color(hex: strokeInt64)
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
    .doneByOthersNhw: MapMarkerColor(statusDoneByOthersNhwColorCode),
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

internal let filteredOutMarkerAlpha = 0.2
private let filteredOutMarkerStrokeAlpha = 0.5
private let filteredOutMarkerFillAlpha = 0.2
private let filteredOutDotStrokeAlpha = 0.2
private let filteredOutDotFillAlpha = 0.05
private let duplicateMarkerAlpha = 0.3

func getWorkTypeFillColor(
    _ status: WorkTypeStatus,
    _ isClaimed: Bool
) -> Color {
    let statusClaim = WorkTypeStatusClaim(status, isClaimed)
    return getMapMarkerColor(statusClaim).fill
}

internal func getMapMarkerColor(
    _ statusClaim: WorkTypeStatusClaim,
    isVisited: Bool = false
) -> MapMarkerColor {
    var markerColors = statusClaimMapMarkerColors[statusClaim]
    if markerColors == nil,
       let status = statusClaimToStatus[statusClaim] {
        markerColors = statusMapMarkerColors[status]

        if isVisited {
            markerColors = MapMarkerColor(
                markerColors!.fillInt64,
                visitedMarkerColorCode
            )
        }
    }
    return markerColors ?? statusMapMarkerColors[.unknown]!
}

internal func getMapMarkerColors(
    _ statusClaim: WorkTypeStatusClaim,
    isDuplicate: Bool,
    isFilteredOut: Bool,
    isVisited: Bool,
    isDot: Bool = false
) -> MapMarkerColor {
    var colors = getMapMarkerColor(
        statusClaim,
        isVisited: isVisited && !(isDuplicate || isFilteredOut)
    )

    if isDuplicate {
        colors = MapMarkerColor(
            colors.fill.hex(duplicateMarkerAlpha),
            colors.stroke.hex(duplicateMarkerAlpha)
        )
    } else if isFilteredOut {
        colors = MapMarkerColor(
            Color.white.hex(isDot ? filteredOutDotFillAlpha : filteredOutMarkerFillAlpha),
            colors.fill.hex(isDot ? filteredOutDotStrokeAlpha : filteredOutMarkerStrokeAlpha)
        )
    }

    return colors
}
