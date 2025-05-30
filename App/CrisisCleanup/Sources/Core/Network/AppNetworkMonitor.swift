import Combine
import Network

class AppNetworkMonitor: NetworkMonitor {
    private let isOnlineSubject = CurrentValueSubject<Bool, Never>(true)
    let isOnline: any Publisher<Bool, Never>
    let isNotOnline: any Publisher<Bool, Never>

    private let pathMonitor = NWPathMonitor()

    private let isNetworkExpensiveOrConstrained = CurrentValueSubject<Bool, Never>(true)
    private(set) var isInternetConnectedUnmetered = false

    private var disposables = Set<AnyCancellable>()

    init() {
        isOnline = isOnlineSubject
        isNotOnline = isOnline
            .eraseToAnyPublisher()
            .map { !$0 }

        pathMonitor.pathUpdateHandler = { path in
            self.isOnlineSubject.value = path.status == .satisfied
            self.isNetworkExpensiveOrConstrained.value = path.isExpensive || path.isConstrained
        }

        Publishers.CombineLatest(
            isOnlineSubject,
            isNetworkExpensiveOrConstrained
        )
        .map { (isOnline, isLimited) in
            isOnline && !isLimited
        }
        .assign(to: \.isInternetConnectedUnmetered, on: self)
        .store(in: &disposables)

        let queue = DispatchQueue(label: "network-monitor")
        pathMonitor.start(queue: queue)
    }

    deinit {
        pathMonitor.cancel()
        _ = cancelSubscriptions(disposables)
    }
}
