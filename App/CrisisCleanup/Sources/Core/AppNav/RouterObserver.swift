import Combine

public protocol RouterObserver {
    var pathIds: any Publisher<[Int], Never> { get }

    func onRouterChange(_ path: [NavigationRoute])

    func isInPath(_ id: Int) -> Bool
}

class AppRouteObserver: RouterObserver {
    let pathIdsSubject = CurrentValueSubject<[Int], Never>([])
    let pathIds: any Publisher<[Int], Never>

    init() {
        pathIds = pathIdsSubject
    }

    func onRouterChange(_ path: [NavigationRoute]) {
        pathIdsSubject.value = path.map { $0.id }
    }

    func isInPath(_ id: Int) -> Bool {
        pathIdsSubject.value.contains(id)
    }
}
