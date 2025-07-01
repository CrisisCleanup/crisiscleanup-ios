import Combine
import CombineExt

extension Publisher where Self.Failure == Never {
    func sink(receiveValue: @escaping ((Self.Output) async -> Void)) -> AnyCancellable {
        sink { value in
            Task {
                await receiveValue(value)
            }
        }
    }
}

extension Publisher where Failure == Never {
    func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    promise(.success(await transform(value)))
                }
            }
        }
    }
}

extension Publisher {
    func mapLatest<T>(
        _ transform: @escaping @Sendable (Output) async throws -> T,
    ) -> AnyPublisher<T, Failure> where Output: Sendable, T: Sendable {
        map { value in
            Deferred {
                Future<T, Error> { promise in
                    Task {
                        do {
                            let result = try await transform(value)
                            try Task.checkCancellation()
                            promise(.success(result))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .catch { error -> Empty<T, Never> in
                if !(error is CancellationError) {
                    // TODO: Handle error
                }
                return Empty()
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
}

// https://medium.com/geekculture/from-combine-to-async-await-c08bf1d15b77
enum AsyncPublisherError: Error {
    case finishedWithoutValue
}
extension AnyPublisher {
    func asyncFirst() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finishedWithoutValue = true
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(throwing: AsyncPublisherError.finishedWithoutValue)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(value))
                }
        }
    }
}

func cancelSubscriptions(_ subscriptions: Set<AnyCancellable>) -> Set<AnyCancellable> {
    let copy = subscriptions
    for s in copy {
        s.cancel()
    }
    return Set<AnyCancellable>()
}

extension Publisher {
    func shareReplay(_ bufferSize: Int) -> AnyPublisher<Output, Failure> {
        share(replay: bufferSize)
            .eraseToAnyPublisher()
    }

    func replay1() -> AnyPublisher<Output, Failure> {
        shareReplay(1)
    }
}
