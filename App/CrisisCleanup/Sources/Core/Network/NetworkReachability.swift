import Alamofire
import Combine

class NetworkReachability: NetworkMonitor {
    @Published private var isOnlineStream = false

    lazy var isOnline = $isOnlineStream
    lazy var isNotOnline = $isOnlineStream

    private let reachabilityManager: NetworkReachabilityManager

    init(_ host: String = "https://crisiscleanup.org") {
        reachabilityManager = NetworkReachabilityManager(host: host)!
        $isOnlineStream.map{ !$0 }.assign(to: &isNotOnline)
        startNetworkMonitoring()
    }

    func startNetworkMonitoring() {
        reachabilityManager.startListening { status in
            switch status {
            case .reachable(.cellular),
                    .reachable(.ethernetOrWiFi):
                self.isOnlineStream = true
            case .notReachable,
                    .unknown:
                self.isOnlineStream = false
            }
        }
    }
}
