import Combine

public protocol DataDownloadSpeedMonitor {
    var isSlowSpeed: any Publisher<Bool, Never> { get }

    func onSpeedChange(isSlow: Bool)
}

class IncidentDataDownloadSpeedMonitor: DataDownloadSpeedMonitor {
    private let isSlowSpeedSubject = CurrentValueSubject<Bool, Never>(false)
    var isSlowSpeed: any Publisher<Bool, Never>

    init() {
        self.isSlowSpeed = isSlowSpeedSubject
            .removeDuplicates()
            .share()
            .eraseToAnyPublisher()
    }

    func onSpeedChange(isSlow: Bool) {
        isSlowSpeedSubject.value = isSlow
    }
}
