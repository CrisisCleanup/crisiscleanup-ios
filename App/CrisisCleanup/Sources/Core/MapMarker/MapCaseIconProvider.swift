import SwiftUI

public protocol MapCaseIconProvider {
    /**
     * Offset to the center of the icon (in pixels)
     */
    var iconOffset: (Double, Double) { get }

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFavorite: Bool,
        isImportant: Bool,
        isFilteredOut: Bool,
        isDuplicate: Bool,
        isMarkedForDelete: Bool,
        isVisited: Bool,
        hasPhotos: Bool,
    ) -> UIImage?

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFilteredOut: Bool,
        isDuplicate: Bool,
        isMarkedForDelete: Bool,
        isVisited: Bool,
        hasPhotos: Bool,
    ) -> UIImage?
}

extension MapCaseIconProvider {
    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFavorite: Bool,
        isImportant: Bool,
    ) -> UIImage? {
        getIcon(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFavorite: isFavorite,
            isImportant: isImportant,
            isFilteredOut: false,
            isDuplicate: false,
            isMarkedForDelete: false,
            isVisited: false,
            hasPhotos: false,
        )
    }

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
    ) -> UIImage? {
        getIcon(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFilteredOut: false,
            isDuplicate: false,
            isMarkedForDelete: false,
            isVisited: false,
            hasPhotos: false,
        )
    }
}
