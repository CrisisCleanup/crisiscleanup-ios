import Foundation

private enum State: String, CaseIterable {
    case ready = "isReady"
    case executing = "isExecuting"
    case finished = "isFinished"
}

class AsyncOperation: Operation, @unchecked Sendable {
    private var state: State = .ready {
        willSet {
            willChangeValue(forKey: newValue.rawValue)
            willChangeValue(forKey: state.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }

    override var isReady: Bool {
        super.isReady && state == .ready
    }

    override var isExecuting: Bool {
        state == .executing
    }

    override var isFinished: Bool {
        state == .finished
    }

    override var isAsynchronous: Bool {
        true
    }

    override func start() {
        guard !isCancelled else {
            state = .finished
            return
        }
        state = .executing

        Task {
            await operate()

            await MainActor.run {
                self.state = .finished
            }
        }
    }

    func operate() async {}
}
