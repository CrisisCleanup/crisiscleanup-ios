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
        isVisited: Bool
    ) -> UIImage?

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFilteredOut: Bool,
        isDuplicate: Bool,
        isVisited: Bool
    ) -> UIImage?
}

extension MapCaseIconProvider {
    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFavorite: Bool,
        isImportant: Bool,
        isFilteredOut: Bool = false,
        isDuplicate: Bool = false,
        isVisited: Bool = false
    ) -> UIImage? {
        getIcon(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFavorite: isFavorite,
            isImportant: isImportant,
            isFilteredOut: isFilteredOut,
            isDuplicate: isDuplicate,
            isVisited: isVisited
        )
    }

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFilteredOut: Bool = false,
        isDuplicate: Bool = false,
        isVisited: Bool = false
    ) -> UIImage? {
        getIcon(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFilteredOut: isFilteredOut,
            isDuplicate: isDuplicate,
            isVisited: isVisited
        )
    }
}
