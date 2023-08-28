import Combine

struct ExistingWorksiteIdentifier {
    let incidentId: Int64
    let worksiteId: Int64

    var isDefined: Bool {
        incidentId != EmptyIncident.id &&
        worksiteId != EmptyWorksite.id
    }
}

let ExistingWorksiteIdentifierNone = ExistingWorksiteIdentifier(
    incidentId: EmptyIncident.id,
    worksiteId: EmptyWorksite.id
)

public class ExistingWorksiteSelector {
    private let worksiteProvider: EditableWorksiteProvider
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let logger: AppLogger

    let selected = CurrentValueSubject<ExistingWorksiteIdentifier, Never>(ExistingWorksiteIdentifierNone)

    init(
        worksiteProvider: EditableWorksiteProvider,
        incidentsRepository: IncidentsRepository,
        worksitesRepository: WorksitesRepository,
        loggerFactory: AppLoggerFactory
    ) {
        self.worksiteProvider = worksiteProvider
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        logger = loggerFactory.getLogger("existing-worksite-selector")
    }

    func onNetworkWorksiteSelected(networkWorksiteId: Int64) async {
        do {
            let incidentId = worksiteProvider.editableWorksite.value.incidentId
            if let incident = try incidentsRepository.getIncident(incidentId, false) {
                let worksiteId = try  worksitesRepository.getLocalId(networkWorksiteId)
                if worksiteId > 0 {
                    selected.value = ExistingWorksiteIdentifier(
                        incidentId: incidentId,
                        worksiteId: worksiteId
                    )
                }
            }
        } catch {
            logger.logError(error)
        }
    }
}
