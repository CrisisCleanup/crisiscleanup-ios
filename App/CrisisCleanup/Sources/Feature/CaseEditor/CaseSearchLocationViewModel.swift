import Combine
import Foundation
import SwiftUI

class CaseSearchLocationViewModel: ObservableObject {
    private let addressSearchRepository: AddressSearchRepository

    @Published var searchQuery = ""
    @Published private(set) var searchResults: [KeyLocationAddress] = []

    private var subscriptions = Set<AnyCancellable>()

    init (
        addressSearchRepository: AddressSearchRepository
    ) {
        self.addressSearchRepository = addressSearchRepository
    }

    func onViewAppear() {
        subscribeToSearch()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeToSearch() {
        let searchQueryIntermediate = $searchQuery
            .debounce(
                for: .seconds(0.2),
                scheduler: RunLoop.current
            )
            .map { $0.trim() }
            .removeDuplicates()

        // TODO: replace with single publisher?
        let subscription = Publishers.CombineLatest(
            searchQueryIntermediate,
            searchQueryIntermediate
        )
        .asyncThrowsMap { (q, q2) in
//                Task { @MainActor in self.isLoading = true }
                do {
                    defer {
//                        Task { @MainActor in self.isLoading = false }
                    }
                    // TODO: include correction parameters from Incident
                    let results = await self.addressSearchRepository.searchAddresses(
                        q,
                        countryCodes: ["USA"],
                        center: nil,
                        southwest: nil,
                        northeast: nil,
                        maxResults: 10
                    )
                    return results
                }
        }
        .receive(on: RunLoop.main)
        .assign(to: \.searchResults, on: self)
        subscriptions.insert(subscription)
    }
}
