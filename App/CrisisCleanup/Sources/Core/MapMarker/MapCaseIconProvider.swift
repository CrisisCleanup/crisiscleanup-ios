import SwiftUI

public protocol MapCaseIconProvider {
    /**
     * Offset to the center of the icon (in pixels)
     */
    var iconOffset: (Double, Double) { get }

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ isFavorite: Bool,
        _ isImportant: Bool,
        _ hasMultipleWorkTypes: Bool
    ) -> UIImage?

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool
    ) -> UIImage?
}
