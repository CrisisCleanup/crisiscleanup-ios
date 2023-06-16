import Alamofire
import Combine

class NetworkReachability: NetworkMonitor {
    @Published private var isOnlineStream = true
    lazy private(set) var isOnline = $isOnlineStream

    @Published private var isNotOnlineStream = false
    lazy private(set) var isNotOnline = $isNotOnlineStream

    private let reachabilityManager: NetworkReachabilityManager

    init(_ host: String = "https://crisiscleanup.org") {
        reachabilityManager = NetworkReachabilityManager(host: host)!
        $isOnlineStream.map { !$0 }
            .assign(to: &isNotOnline)
        startNetworkMonitoring()
    }

    func startNetworkMonitoring() {
        reachabilityManager.startListening { status in
            switch status {
            case .reachable(.cellular),
                    .reachable(.ethernetOrWiFi):
                self.isOnlineStream = true
#if targetEnvironment(simulator)
            case .notReachable:
                self.isOnlineStream = true
            case .unknown:
                self.isOnlineStream = false
#else
            case .notReachable,
                    .unknown:
                self.isOnlineStream = false
#endif
            }
        }
    }
}
