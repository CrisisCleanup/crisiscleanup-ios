import Atomics
import Foundation

public class IncidentRefresher {
    private let incidentsRepository: IncidentsRepository
    private let logger: AppLogger

    private let recentlyRefreshedIncident = ManagedAtomic(EmptyIncident.id)

    init(
        _ incidentsRepository: IncidentsRepository,
        _ loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        logger = loggerFactory.getLogger("incident-refresh")
    }

    func pullIncident(_ id: Int64) async {
        do {
            if recentlyRefreshedIncident.exchange(id, ordering: .releasing) == id {
                return
            }

            try await incidentsRepository.pullIncident(id)
            await incidentsRepository.pullIncidentOrganizations(id)
        } catch {
            logger.logDebug(error.localizedDescription)
        }
    }
}

public class LanguageRefresher {
    private let languageRepository: LanguageTranslationsRepository

    private var lastRefresh = Date(timeIntervalSince1970: 0).timeIntervalSince1970

    init(
        _ languageRepository: LanguageTranslationsRepository
    ) {
        self.languageRepository = languageRepository
    }

    func pullLanguages() async {
        let now = Date.now.timeIntervalSince1970
        if now - lastRefresh > 6.hours {
            lastRefresh = now

            await languageRepository.loadLanguages()
        }
    }
}

public class OrganizationRefresher {
    private let accountDataRefresher: AccountDataRefresher

    private var incidentIdPull = EmptyIncident.id
    private var lastRefresh = Date(timeIntervalSince1970: 0).timeIntervalSince1970

    init(
        _ accountDataRefresher: AccountDataRefresher
    ) {
        self.accountDataRefresher = accountDataRefresher
    }

    func pullOrganization(_ incidentId: Int64) {
        let now = Date.now.timeIntervalSince1970
        if incidentIdPull != incidentId ||
            now - lastRefresh > 1.hours {
            incidentIdPull = incidentId
            lastRefresh = now

            Task {
                await self.accountDataRefresher.updateMyOrganization(true)
            }
        }
    }
}
