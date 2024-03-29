import SwiftUI
import MapKit

class WorksiteAnnotationMapMark: MKPointAnnotation {
    var source: WorksiteMapMark!
    var point: MKPointAnnotation!
    var mapIcon: UIImage? = nil
    var reuseIdentifier: String!
    var isFilteredOut: Bool { source.isFilteredOut }
    // let mapIconOffset: Offset

    override init() {}
}

extension WorksiteMapMark {
    func asAnnotationMapMark(
        _ iconProvider: MapCaseIconProvider,
        _ isVisited: Bool,
        _ additionalScreenOffset: (Double, Double)
    ) -> WorksiteAnnotationMapMark {
        // let (xOffset, yOffset) = additionalScreenOffset

        let point = WorksiteAnnotationMapMark()
        point.coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        point.source = self
        // TODO: Get an identifier based on the icon descriptor as well. Likely status-claim-worktype|favorite|high-priority
        let hasMultipleWorkTypes = workTypeCount > 1
        point.mapIcon = iconProvider.getIcon(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFavorite: isFavorite,
            isImportant: isHighPriority,
            isFilteredOut: isFilteredOut,
            isVisited: isVisited
        )

        let statusId = statusClaim.status.literal
        // Match logic in work type icon resolver
        var lookupKey = workType
        if isFavorite {
            lookupKey = .favorite
        }
        else if isHighPriority {
            lookupKey = .important
        }
        let workTypeId = lookupKey.rawValue

        let isClaimed = statusClaim.isClaimed
        let remainingIds: Int64 = (isClaimed ? 1 << 0 : 0) |
        (hasMultipleWorkTypes ? 1 << 1 : 0) |
        (isFilteredOut ? 1 << 2 : 0) |
        (isDuplicate ? 1 << 3 : 0) |
        (isVisited ? 1 << 4 : 0)
        point.reuseIdentifier = "\(statusId)-\(workTypeId)-\(remainingIds)"

        // mapIconOffset = Offset(0.5f + xOffset, 0.5f + yOffset),

        return point
    }
}
