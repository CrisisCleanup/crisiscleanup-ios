import Combine

protocol NetworkMonitor {
    var isOnline: Published<Bool>.Publisher { get }
    var isNotOnline: Published<Bool>.Publisher { get }
}
