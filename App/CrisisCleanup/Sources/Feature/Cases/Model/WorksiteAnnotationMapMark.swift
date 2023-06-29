import SwiftUI
import MapKit

class WorksiteAnnotationMapMark: MKPointAnnotation {
    var source: WorksiteMapMark!
    var point: MKPointAnnotation!
    var mapIcon: UIImage? = nil
    var reuseIdentifier: String!
    // let mapIconOffset: Offset

    override init() {}
}

extension WorksiteMapMark {
    func asAnnotationMapMark(
        _ iconProvider: MapCaseIconProvider,
        _ additionalScreenOffset: (Double, Double)
    ) -> WorksiteAnnotationMapMark {
        let (xOffset, yOffset) = additionalScreenOffset

        let point = WorksiteAnnotationMapMark()
        point.coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        point.source = self
        // TODO: Get an identifier based on the icon descriptor as well. Likely status-claim-worktype|favorite|high-priority
        point.mapIcon = iconProvider.getIcon(
            statusClaim,
            workType,
            isFavorite,
            isHighPriority,
            workTypeCount > 1
        )
        point.reuseIdentifier = "\(self.id)"
        // mapIconOffset = Offset(0.5f + xOffset, 0.5f + yOffset),
        return point
    }
}
