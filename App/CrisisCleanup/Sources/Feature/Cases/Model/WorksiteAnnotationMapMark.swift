import SwiftUI
import MapKit

class WorksiteAnnotationMapMark: MKPointAnnotation {
    var source: WorksiteMapMark!
    var point: MKPointAnnotation!
    var mapIcon: UIImage? = nil
    var reuseIdentifier: String!
    var isFilteredOut: Bool!
    // let mapIconOffset: Offset

    override init() {}
}

extension WorksiteMapMark {
    func asAnnotationMapMark(
        _ iconProvider: MapCaseIconProvider,
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
            isFilteredOut: isFilteredOut
        )

        let statusId = statusClaim.status.literal
        let isClaimed = statusClaim.isClaimed
        // Match logic in work type icon resolver
        var lookupKey = workType
        if isFavorite {
            lookupKey = .favorite
        }
        else if isHighPriority {
            lookupKey = .important
        }
        let workTypeId = lookupKey.rawValue

        point.reuseIdentifier = "\(statusId)-\(isClaimed)-\(workTypeId)-\(hasMultipleWorkTypes)"

        point.isFilteredOut = isFilteredOut

        // mapIconOffset = Offset(0.5f + xOffset, 0.5f + yOffset),

        return point
    }
}
