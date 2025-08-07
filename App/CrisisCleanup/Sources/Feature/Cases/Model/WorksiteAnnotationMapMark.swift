import SwiftUI
import MapKit

class WorksiteAnnotationMapMark: MKPointAnnotation {
    var source: WorksiteMapMark!
    var point: MKPointAnnotation!
    var mapIcon: UIImage? = nil
    var reuseIdentifier: String!
    var isFilteredOut: Bool { source.isFilteredOut }
    var mapIconOffset: CGPoint = .zero

    override init() {}
}

extension WorksiteMapMark {
    func asAnnotationMapMark(
        _ iconProvider: MapCaseIconProvider,
        _ isVisited: Bool,
        _ additionalScreenOffset: CGPoint,
    ) -> WorksiteAnnotationMapMark {
        let point = WorksiteAnnotationMapMark()
        point.coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        point.source = self
        let hasMultipleWorkTypes = workTypeCount > 1
        point.mapIcon = iconProvider.getIcon(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFavorite: isFavorite,
            isImportant: isHighPriority,
            isFilteredOut: isFilteredOut,
            isDuplicate: isDuplicate,
            isMarkedForDelete: isMarkedForDelete,
            isVisited: isVisited,
            hasPhotos: hasPhotos,
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
        let remainingIdentifier: Int64 = (isClaimed ? 1 << 0 : 0) |
        (hasMultipleWorkTypes ? 1 << 1 : 0) |
        (isFilteredOut ? 1 << 2 : 0) |
        (isDuplicate || isMarkedForDelete ? 1 << 3 : 0) |
        (isVisited ? 1 << 4 : 0) |
        (hasPhotos ? 1 << 5 : 0)
        let hasOffset = additionalScreenOffset != .zero
        let offsetIdentifier = hasOffset ? "\(additionalScreenOffset.x)-\(additionalScreenOffset.y)" : "0"
        point.reuseIdentifier = "\(statusId)-\(workTypeId)-\(remainingIdentifier)-\(offsetIdentifier)"

        point.mapIconOffset = additionalScreenOffset

        return point
    }
}
