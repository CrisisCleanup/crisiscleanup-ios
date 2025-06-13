import Combine
import Foundation
import SwiftUI

class SyncInsightsViewModel: ObservableObject {
    private let syncLogRepository: SyncLogRepository
    private let worksitesRepository: WorksitesRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    @Published private(set) var worksitesPendingSync = [(Int64, String)]()

    @Published private(set) var isSyncing = false

    private let queryLogState = CurrentValueSubject<(Int, Int), Never>((0, 0))

    @Published private(set) var syncLogs = [SyncLogItem]()

    private var subscriptions = Set<AnyCancellable>()

    init(
        syncLogRepository: SyncLogRepository,
        worksitesRepository: WorksitesRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        syncPusher: SyncPusher,
        loggerFactory: AppLoggerFactory
    ) {
        self.syncLogRepository = syncLogRepository
        self.worksitesRepository = worksitesRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.syncPusher = syncPusher
        logger = loggerFactory.getLogger("sync-insights")
    }

    func onViewAppear() {
        subscribeToSyncing()
        subscribeToLogCount()
        subscribeToPendingSync()
        subscribeToSyncLogs()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeToSyncing() {
        worksiteChangeRepository.syncingWorksiteIds.eraseToAnyPublisher()
            .map { !$0.isEmpty }
            .receive(on: RunLoop.main)
            .assign(to: \.isSyncing, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToLogCount() {
        syncLogRepository.streamLogCount()
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { totalCount in
                self.queryLogState.value = (0, totalCount)
            })
            .store(in: &subscriptions)
    }

    private func subscribeToPendingSync() {
        worksiteChangeRepository.streamWorksitesPendingSync
            .eraseToAnyPublisher()
            .map {
                $0.map { worksite in
                    (
                        worksite.id,
                        "(\(worksite.incidentId), \(worksite.id)) \(worksite.caseNumber)"
                    )
                }
            }
        .receive(on: RunLoop.main)
        .assign(to: \.worksitesPendingSync, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeToSyncLogs() {
        queryLogState
            .map { (startIndex, totalCount) in
                let logs = self.syncLogRepository.getLogs(100, 0)
                let logItems = logs.enumerated().map { index, log in
                    let isContinuingLogType = index > 0 && logs[index - 1].logType == log.logType
                    return SyncLogItem(
                        index: index,
                        syncLog: log,
                        isContinuingLogType: isContinuingLogType,
                        relativeTime: log.logTime.relativeTime
                    )
                }
                return logItems
            }
            .receive(on: RunLoop.main)
            .assign(to: \.syncLogs, on: self)
            .store(in: &subscriptions)
    }

    func syncPending() {
        if worksitesPendingSync.isNotEmpty {
            logger.logDebug("Functionality is no longer necessary")
        }
    }
}

public struct SyncLogItem {
    let index: Int
    let syncLog: SyncLog
    let isContinuingLogType: Bool
    let relativeTime: String
}
