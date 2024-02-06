import Alamofire
import Foundation

struct WrapResponseKeyPreprocessor: DataPreprocessor {
    private let wrapKey: String

    init(_ key: String) {
        wrapKey = key
    }
    func preprocess(_ data: Data) throws -> Data {
        // TODO: Perform operations on data directly rather than decoding, operating, encoding
        var wrapped = String(decoding: data, as: UTF8.self)
        wrapped = "{\"\(wrapKey)\":\(wrapped)}"
        return wrapped.data(using: .utf8)!
    }
}
