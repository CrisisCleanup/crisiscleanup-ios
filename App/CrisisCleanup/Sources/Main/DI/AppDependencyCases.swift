import Foundation
import SwiftUI

extension MainComponent {
    public var incidentBoundsProvider: IncidentBoundsProvider {
        shared {
            MapsIncidentBoundsProvider(
                incidentsRepository: incidentsRepository,
                locationsRepository: locationsRepository
            )
        }
    }

    public var mapCaseIconProvider: MapCaseIconProvider {
        shared {
            NullMapCaseIconProvider()
        }
    }
}

private class NullMapCaseIconProvider: MapCaseIconProvider {
    func getIcon(_ statusClaim: WorkTypeStatusClaim, _ workType: WorkTypeType, _ isFavorite: Bool, _ isImportant: Bool, _ hasMultipleWorkTypes: Bool) -> UIImage? {
        nil
    }

    func getIconBitmap(_ statusClaim: WorkTypeStatusClaim, _ workType: WorkTypeType, _ hasMultipleWorkTypes: Bool) -> UIImage? {
        nil
    }
}
