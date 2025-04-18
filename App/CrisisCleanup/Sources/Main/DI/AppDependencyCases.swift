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

    public var worksiteLocationEditor: WorksiteLocationEditor {
        editableWorksiteProvider as! WorksiteLocationEditor
    }

    public var incidentRefresher: IncidentRefresher {
        shared {
            IncidentRefresher(
                incidentsRepository,
                loggerFactory
            )
        }
    }

    public var languageRefresher: LanguageRefresher {
        shared {
            LanguageRefresher(
                languageTranslationsRepository
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

    public var existingWorksiteSelector: ExistingWorksiteSelector {
        shared {
            ExistingWorksiteSelector(
                worksiteProvider: editableWorksiteProvider,
                incidentsRepository: incidentsRepository,
                worksitesRepository: worksitesRepository,
                loggerFactory: loggerFactory
            )
        }
    }

    public var worksiteInteractor: WorksiteInteractor {
        shared {
            CasesWorksiteInteractor(
                incidentSelector: incidentSelector
            )
        }
    }

    public var incidentMapTracker: IncidentMapTracker {
        shared {
            AppIncidentMapTracker(preferenceDataSource: appPreferences)
        }
    }
}
