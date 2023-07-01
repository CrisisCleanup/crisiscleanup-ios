import Combine

extension Publisher where Self.Failure == Never {
    func sink(receiveValue: @escaping ((Self.Output) async -> Void)) -> AnyCancellable {
        sink { value in
            Task {
                await receiveValue(value)
            }
        }
    }
}

extension Publisher where Self.Failure == Never {
    func asyncMap<T>(_ transform: @escaping ((Self.Output) async -> T)) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    promise(.success(await transform(value)))
                }
            }
        }
    }

    func asyncThrowsMap<T>(_ transform: @escaping ((Self.Output) async throws -> T)) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    promise(.success(try await transform(value)))
                }
            }
        }
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
