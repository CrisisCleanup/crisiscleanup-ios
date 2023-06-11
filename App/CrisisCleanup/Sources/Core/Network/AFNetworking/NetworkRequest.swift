import Alamofire
import Foundation

// sourcery: copyBuilder
struct NetworkRequest: URLRequestConvertible {
    let url: URL
    let method: HTTPMethod
    let headers: HTTPHeaders?
    let additionalPaths: [String]?
    let queryParameters: [URLQueryItem]?
    let formParameters: Encodable?
    let bodyParameters: Encodable?
    let addTokenHeader: Bool
    let wrapResponseKey: String?

    init(
        _ url: URL,
        method: HTTPMethod = .get,
        headers: HTTPHeaders? = nil,
        additionalPaths: [String]? = nil,
        queryParameters: [URLQueryItem]? = nil,
        formParameters: Encodable? = nil,
        bodyParameters: Encodable? = nil,
        addTokenHeader: Bool = false,
        wrapResponseKey: String = ""
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.additionalPaths = additionalPaths
        self.queryParameters = queryParameters
        self.formParameters = formParameters
        self.bodyParameters = bodyParameters
        self.addTokenHeader = addTokenHeader
        self.wrapResponseKey = wrapResponseKey
    }

    func addPaths(_ paths: String...) -> NetworkRequest {
        return copy { $0.additionalPaths = paths }
    }

    func addQueryItems(_ pairs: String?...) -> NetworkRequest {
        var qs: [URLQueryItem] = []
        for i in stride(from: 0, to: pairs.count, by: 2) {
            let name = pairs[i]
            let value = pairs[i+1]
            if name != nil && value != nil {
                qs.append(URLQueryItem(name: name!, value: value!))
            }
        }

        return qs.isEmpty ? self : copy { $0.queryParameters = qs }
    }

    func asURLRequest() throws -> URLRequest {
        return with(URLRequest(url: url)) { request in
            var url = url

            if let paths = additionalPaths {
                paths.forEach {
                    url = url.appending(path: $0)
                }
            }

            request.method = method
            headers?.forEach { h in
                request.setValue(h.name, forHTTPHeaderField: h.value)
            }
            if let q = queryParameters {
                url = url.appending(queryItems: q)
            }

            if addTokenHeader {
                request.setValue("", forHTTPHeaderField: "Authorization")
            }

            if wrapResponseKey?.isNotBlank == true {
                request.setValue(wrapResponseKey!, forHTTPHeaderField: "wrap-response-key")
            }

            if let parameters = formParameters {
                request = try! URLEncodedFormParameterEncoder().encode(
                    parameters,
                    into: request
                )
            }

            if let parameters = bodyParameters {
                request = try! JSONParameterEncoder().encode(
                    parameters,
                    into: request
                )
                request.setValue("application/json", forHTTPHeaderField: "Accept")
            }
        }
    }
}
