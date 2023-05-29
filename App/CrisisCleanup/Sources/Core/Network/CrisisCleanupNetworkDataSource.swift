public protocol CrisisCleanupAuthApi {
    func login(_ email: String, _ password: String) async throws -> NetworkAuthResult
}
