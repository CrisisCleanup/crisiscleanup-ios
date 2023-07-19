import Atomics
import Foundation

public class IncidentRefresher {
    private let incidentsRepository: IncidentsRepository
    private let networkMonitor: NetworkMonitor
    private let logger: AppLogger

    private let recentlyRefreshedIncident = ManagedAtomic<Int64>(EmptyIncident.id)

    init(
        _ incidentsRepository: IncidentsRepository,
        _ networkMonitor: NetworkMonitor,
        _ loggerFactory: AppLoggerFactory
    ) {
        self.incidentsRepository = incidentsRepository
        self.networkMonitor = networkMonitor
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
    private let networkMonitor: NetworkMonitor
    private let logger: AppLogger

    init(
        _ languageRepository: LanguageTranslationsRepository,
        _ networkMonitor: NetworkMonitor,
        _ loggerFactory: AppLoggerFactory
    ) {
        self.languageRepository = languageRepository
        self.networkMonitor = networkMonitor
        logger = loggerFactory.getLogger("language-refresh")
    }
    private let lastLoadTime = ManagedAtomic<AtomicDouble>(AtomicDouble(Date(timeIntervalSince1970: 0).timeIntervalSince1970))

    func pullLanguages() async {
        let now = Date.now.timeIntervalSince1970
        if now - lastLoadTime.load(ordering: .acquiring).value > 6.hours {
            await languageRepository.loadLanguages()
            lastLoadTime.store(AtomicDouble(now), ordering: .relaxed)
        }
    }
}

private class AtomicDouble: AtomicValue {
    typealias AtomicRepresentation = AtomicReferenceStorage<AtomicDouble>

    let value: Double

    init(_ value: Double = 0.0) {
        self.value = value
    }
}
