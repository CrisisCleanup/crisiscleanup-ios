import Combine

// TODO: Migrate to CombineExt flatMapLatest
//       Also migrate map+switchToLatest
public class LatestAsyncPublisher<T> {
    private var cancellable: Task<(), Never>?

    public func publisher(_ transform: @escaping () async -> T) -> AnyPublisher<T, Never> {
        cancellable?.cancel()

        let subject = PassthroughSubject<T, Never>()
        cancellable = Task {
            let result = await transform()
            subject.send(result)
        }

        return subject
            .assertNoFailure()
            .eraseToAnyPublisher()
    }
}

public class LatestAsyncThrowsPublisher<T> {
    private let errorHandler: (Error) -> Void
    private var cancellable: Task<(), Never>?

    public init(
        errorHandler: @escaping (Error) -> Void = { _ in }
    ) {
        self.errorHandler = errorHandler
    }

    public func publisher(_ transform: @escaping () async throws -> T) -> AnyPublisher<T, Never> {

        cancellable?.cancel()

        let subject = PassthroughSubject<T, Never>()
        cancellable = Task {
            do {
                let result = try await transform()
                subject.send(result)
            } catch {
                if !(error is CancellationError) {
                    errorHandler(error)
                }
            }
        }

        return subject
            .assertNoFailure()
            .eraseToAnyPublisher()
    }
}
