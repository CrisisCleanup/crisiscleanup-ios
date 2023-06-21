import Foundation

extension KeyedDecodingContainer {
    func decodeIterableString(_ key: KeyedDecodingContainer<Key>.Key) -> [String]? {
        if let single = try? decodeIfPresent(String.self, forKey: key) {
            return [single]
        } else if let many = try? decodeIfPresent([String].self, forKey: key) {
            return many
        }
        return nil
    }
}

class JsonDecoderFactory {
    func decoder(
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
    ) -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
        return jsonDecoder
    }
}

extension JSONEncoder {
    func encodeToString(_ payload: Encodable) throws -> String {
        let data = try encode(payload)
        return String(decoding: data, as: UTF8.self)
    }
}