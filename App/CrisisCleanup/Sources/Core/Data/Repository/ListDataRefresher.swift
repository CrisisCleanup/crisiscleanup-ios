import Foundation

public class ListDataRefresher {
    private let listsSyncer: ListsSyncer
    private let logger: AppLogger

    private var dataUpdateTime = Date(timeIntervalSince1970: 0)

    init(
        listsSyncer: ListsSyncer,
        loggerFactory: AppLoggerFactory
    ) {
        self.listsSyncer = listsSyncer
        logger = loggerFactory.getLogger("lists")
    }

    func refreshListData(
        force: Bool = false,
        cacheTimeSpan: Double = 1.hours
    ) async {
        if !force,
           dataUpdateTime.addingTimeInterval(cacheTimeSpan) > Date.now {
            return
        }

        do {
            try await listsSyncer.sync()
            dataUpdateTime = Date.now
        } catch {
            logger.logError(error)
        }
    }
}
