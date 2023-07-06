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
            WorkTypeIconProvider()
        }
    }

    public var editableWorksiteProvider: EditableWorksiteProvider {
        shared {
            SingleEditableWorksiteProvider()
        }
    }
}
