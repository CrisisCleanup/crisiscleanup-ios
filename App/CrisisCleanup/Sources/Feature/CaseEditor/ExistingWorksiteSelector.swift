import Combine

public class ExistingWorksiteSelector {
    private let worksiteProvider: EditableWorksiteProvider
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let logger: AppLogger

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

    func onNetworkWorksiteSelected(networkWorksiteId: Int64) async -> ExistingWorksiteIdentifier {
        do {
            let incidentId = worksiteProvider.editableWorksite.value.incidentId
            if let _ = try incidentsRepository.getIncident(incidentId, false) {
                let worksiteId = try  worksitesRepository.getLocalId(networkWorksiteId)
                if worksiteId > 0 {
                    return ExistingWorksiteIdentifier(
                        incidentId: incidentId,
                        worksiteId: worksiteId
                    )
                }
            }
        } catch {
            logger.logError(error)
        }
        return ExistingWorksiteIdentifierNone
    }
}
