import Alamofire
import Combine

class NetworkReachability: NetworkMonitor {
    private let isOnlineSubject = CurrentValueSubject<Bool, Never>(true)
    let isOnline: any Publisher<Bool, Never>
    let isNotOnline: any Publisher<Bool, Never>

    private let reachabilityManager: NetworkReachabilityManager

    init(_ host: String) {
        reachabilityManager = NetworkReachabilityManager(host: host)!

        isOnline = isOnlineSubject
        isNotOnline = isOnline
            .eraseToAnyPublisher()
            .map { !$0 }

        startNetworkMonitoring()
    }

    func startNetworkMonitoring() {
        reachabilityManager.startListening { status in
            switch status {
            case .reachable(.cellular),
                    .reachable(.ethernetOrWiFi):
                self.isOnlineSubject.value = true
            case .notReachable:
                self.isOnlineSubject.value = false
            case .unknown:
                self.isOnlineSubject.value = false
            }
        }
    }
}
