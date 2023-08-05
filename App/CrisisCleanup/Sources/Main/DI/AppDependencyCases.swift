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

    public var incidentRefresher: IncidentRefresher {
        shared {
            IncidentRefresher(
                incidentsRepository,
                networkMonitor,
                loggerFactory
            )
        }
    }

    public var languageRefresher: LanguageRefresher {
        shared {
            LanguageRefresher(
                languageTranslationsRepository,
                networkMonitor,
                loggerFactory
            )
        }
    }

    public var transferWorkTypeProvider: TransferWorkTypeProvider {
        shared {
            SingleTransferWorkTypeProvider()
        }
    }

    public var worksiteProvider: WorksiteProvider {
        shared {
            SingleWorksiteProvider()
        }
    }
}
