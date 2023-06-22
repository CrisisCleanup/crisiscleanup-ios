import SwiftUI

struct WorksiteIconMapMark {
    let source: WorksiteMapMark
    let latLng: LatLng
    // let markerState: MarkerState
     let mapIcon: UIImage?
    // let mapIconOffset: Offset
}

extension WorksiteMapMark {
    func asWorksiteIconMapMark(
        _ iconProvider: MapCaseIconProvider,
        _ additionalScreenOffset: (Double, Double)
    ) -> WorksiteIconMapMark {
        let latLng = LatLng(latitude, longitude)
        let (xOffset, yOffset) = additionalScreenOffset
        return WorksiteIconMapMark(
            source: self,
            latLng: latLng,
            // markerState = MarkerState(latLng),
            mapIcon: iconProvider.getIcon(
                statusClaim,
                workType,
                isFavorite,
                isHighPriority,
                workTypeCount > 1
            )
            // mapIconOffset = Offset(0.5f + xOffset, 0.5f + yOffset),
        )
    }
}
