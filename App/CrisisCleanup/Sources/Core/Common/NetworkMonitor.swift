import Combine

public protocol NetworkMonitor {
    var isOnline: any Publisher<Bool, Never> { get }
    var isNotOnline: any Publisher<Bool, Never> { get }
    var isInternetConnectedUnmetered: Bool { get }
}
