import Alamofire
import Foundation

private let jsonDecoder = JsonDecoderFactory().decoder()

class AccessTokenInterceptor: RequestInterceptor {
    let accountDataRepository: AccountDataRepository

    init(
        accountDataRepository: AccountDataRepository
    ) {
        self.accountDataRepository = accountDataRepository
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest
        if urlRequest.value(forHTTPHeaderField: "Authorization") == "" {
            // TODO: Use the stored access token rather than the cached
            let accessToken = accountDataRepository.accessTokenCached
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        completion(.success(urlRequest))
    }
}
