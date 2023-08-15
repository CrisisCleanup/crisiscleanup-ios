import Combine
import Foundation
import SwiftUI

class CaseHistoryViewModel: ObservableObject {
    private let caseHistoryRepository: CaseHistoryRepository
    let translator: KeyAssetTranslator

    private let worksite: Worksite
    private let worksiteId: Int64

    @Published private(set) var isLoadingCaseHistory = true

    @Published private(set) var screenTitle: String = ""

    @Published private(set) var historyEvents: [CaseHistoryUserEvents] = []

    @Published private(set) var hasEvents: Bool = true

    private var subscriptions = Set<AnyCancellable>()

    init(
        editableWorksiteProvider: EditableWorksiteProvider,
        caseHistoryRepository: CaseHistoryRepository,
        translator: KeyAssetTranslator
    ) {
        self.caseHistoryRepository = caseHistoryRepository
        self.translator = translator

        self.worksite = editableWorksiteProvider.editableWorksite.value

        let worksiteId = worksite.id
        self.worksiteId = worksiteId

        self.screenTitle = "\(translator.t("actions.history")) (\(worksite.caseNumber))"

        Task {
            let eventCount = await caseHistoryRepository.refreshEvents(worksiteId)
            Task { @MainActor in
                hasEvents = eventCount > 0
            }
        }
    }

    func onViewAppear() {
        subscribeLoading()
        subscribeEvents()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        caseHistoryRepository.loadingWorksiteId
            .eraseToAnyPublisher()
            .map { $0 == self.worksiteId }
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingCaseHistory, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeEvents() {
        caseHistoryRepository.streamEvents(worksiteId)
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.historyEvents, on: self)
            .store(in: &subscriptions)
    }
}
