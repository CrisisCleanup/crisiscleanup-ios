import Alamofire
import Foundation

// sourcery: copyBuilder
struct NetworkRequest: URLRequestConvertible {
    let url: URL
    let method: HTTPMethod
    let headers: HTTPHeaders?
    let parameters: Encodable?

    init(
        url: URL,
        method: HTTPMethod,
        headers: HTTPHeaders? = nil,
        parameters: Encodable? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.parameters = parameters
    }

    func asURLRequest() throws -> URLRequest {
        return with(URLRequest(url: url)) { request in
            request.method = method
            headers?.forEach { h in
                request.setValue(h.name, forHTTPHeaderField: h.value)
            }
            if let parameters = self.parameters {
                switch(method) {
                case .get:
                    request = try! URLEncodedFormParameterEncoder().encode(parameters, into: request)
                default:
                    request = try! JSONParameterEncoder().encode(parameters, into: request)
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                }
            }
        }
    }
}
