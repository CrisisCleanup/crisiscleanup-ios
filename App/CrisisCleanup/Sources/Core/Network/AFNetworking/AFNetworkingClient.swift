import Alamofire
import Foundation

class AFNetworkingClient {
    private let appEnv: AppEnv
    private let session: Session

    private let jsonDecoder: JSONDecoder

    init(
        _ appEnv: AppEnv,
        interceptor: RequestInterceptor? = nil,
        jsonDecoder: JSONDecoder? = nil
    ) {
        self.appEnv = appEnv

        let configuration = with(URLSessionConfiguration.af.default) { s in
            s.timeoutIntervalForRequest = 45
            s.timeoutIntervalForResource = 60
        }

        var eventMonitors: [EventMonitor] = []
        if appEnv.isDebuggable {
            eventMonitors.append(LogEventMonitor())
        }

        session = Session(
            configuration: configuration,
            interceptor: interceptor,
            eventMonitors: eventMonitors
        )

        self.jsonDecoder = jsonDecoder ?? JsonDecoderFactory().decoder()
    }

    func request(_ convertible: URLRequestConvertible) -> DataRequest {
        return session.request(convertible)
    }

    func callbackContinue<T: Decodable>(
        requestConvertible: URLRequestConvertible,
        type: T.Type,
        wrapResponseKey: String = ""
    ) async -> DataResponse<T, AFError> {
        let result = await withCheckedContinuation { continuation in
            let dataPreproccessor = wrapResponseKey.isEmpty
            ? DecodableResponseSerializer<T>.defaultDataPreprocessor
            : WrapResponseKeyPreprocessor(wrapResponseKey)
            request(requestConvertible).responseDecodable(
                of: type,
                dataPreprocessor: dataPreproccessor,
                decoder: jsonDecoder
            ) { response in
                continuation.resume(returning: response)
            }
        }
        return result
    }

    func callbackContinue(_ convertible: URLRequestConvertible) async -> DataResponse<Data?, AFError> {
        let result = await withCheckedContinuation { continuation in
            request(convertible).response(completionHandler: { response in
                continuation.resume(returning: response)
            })
        }
        return result
    }

    func uploadFile(
        requestConvertible: URLRequestConvertible,
        multipart: @escaping (MultipartFormData) -> Void
    ) async throws {
        let uploadRequest = AF.upload(
            multipartFormData: multipart,
            with: requestConvertible
        )
        return try await withCheckedThrowingContinuation { continuation in
            uploadRequest.response { response in
                switch response.result {
                case .success(_):
                    var failMessage = ""
                    if let statusCode = response.response?.statusCode,
                       statusCode < 200 || statusCode >= 300 {
                        failMessage = "Upload failed. Status code: \(statusCode)."
                    }
                    if failMessage.isBlank {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: GenericError(failMessage))
                    }
                default:
                    continuation.resume(throwing: response.error ?? GenericError("Upload fail"))
                }
            }
        }
    }
}

private class LogEventMonitor : EventMonitor {
    func requestDidFinish(_ request: Request) {
//        if let headers = request.response?.headers {
//            print(headers)
//        }
//        print(request.description)
    }

    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
//        guard let data = response.data else {
//            return
//        }
//
//        if let json = try? JSONSerialization.jsonObject(with: data) {
//            print(json)
//        }
    }
}
