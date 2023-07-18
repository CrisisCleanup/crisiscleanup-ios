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

    init(
        _ url: URL,
        method: HTTPMethod = .get,
        headers: HTTPHeaders? = nil,
        additionalPaths: [String]? = nil,
        queryParameters: [URLQueryItem]? = nil,
        formParameters: Encodable? = nil,
        bodyParameters: Encodable? = nil,
        addTokenHeader: Bool = false
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.additionalPaths = additionalPaths
        self.queryParameters = queryParameters
        self.formParameters = formParameters
        self.bodyParameters = bodyParameters
        self.addTokenHeader = addTokenHeader
    }

    func addPaths(_ paths: String...) -> Self {
        copy { $0.additionalPaths = paths }
    }

    func addQueryItems(_ pairs: String?...) -> Self {
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

    func addHeaders(_ headers: [String: String]) -> Self {
        if headers.isEmpty {
            return self
        }

        var tempHeaders = self.headers ?? HTTPHeaders()
        for (key, value) in headers {
            tempHeaders.add(name: key, value: value)
        }

        return copy { $0.headers = tempHeaders }
    }

    func setBody(_ body: Encodable) -> Self {
        copy { $0.bodyParameters = body }
    }

    func setForm(_ form: Encodable) -> Self {
        copy { $0.formParameters = form }
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
                request.setValue(h.value, forHTTPHeaderField: h.name)
            }
            if let q = queryParameters {
                url = url.appending(queryItems: q)
            }

            request.url = url

            if addTokenHeader {
                request.setValue("", forHTTPHeaderField: "Authorization")
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
