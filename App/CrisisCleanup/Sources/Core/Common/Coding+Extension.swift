import Foundation

// https://stackoverflow.com/questions/44682626/swifts-jsondecoder-with-multiple-date-formats-in-a-json-string
extension JSONDecoder.DateDecodingStrategy {
    static func anyFormatter(in formatters: [DateFormatter]) -> Self {
        return .custom { decoder in
            guard formatters.count > 0 else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No date formatter provided"))
            }

            guard let dateString = try? decoder.singleValueContainer().decode(String.self) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not decode date string"))
            }

            let successfullyFormattedDates = formatters.lazy.compactMap { $0.date(from: dateString) }

            guard let date = successfullyFormattedDates.first else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Date string \"\(dateString)\" does not match any of the expected formats (\(formatters.compactMap(\.dateFormat).joined(separator: " or ")))"))
            }

            return date
        }
    }
}

extension KeyedDecodingContainer {
    func decodeIterableString(_ key: KeyedDecodingContainer<Key>.Key) -> [String]? {
        if let single = try? decodeIfPresent(String.self, forKey: key) {
            return [single]
        } else if let many = try? decodeIfPresent([String].self, forKey: key) {
            return many
        }
        return nil
    }

    func decodeIterableInt64(_ key: KeyedDecodingContainer<Key>.Key) -> [Int64]? {
        if let single = try? decodeIfPresent(Int64.self, forKey: key) {
            return [single]
        } else if let many = try? decodeIfPresent([Int64].self, forKey: key) {
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

    // TODO: Test coverage. Including locale and time zone.
    func multiDateDecoder() -> JSONDecoder {
        let isoFormat = with(DateFormatter()) {
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        }
        let millisecondsFormat = with(DateFormatter()) {
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        }
        let secondsFormat = with(DateFormatter()) {
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        }
        let jsonDecoder = JsonDecoderFactory().decoder(
            dateDecodingStrategy: .anyFormatter(in: [isoFormat, millisecondsFormat, secondsFormat])
        )

        return jsonDecoder
    }
}

class JsonEncoderFactory {
    func encoder(
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601
    ) -> JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = dateEncodingStrategy
        return jsonEncoder
    }
}

extension JSONEncoder {
    func encodeToString(_ payload: Encodable) throws -> String {
        let data = try encode(payload)
        return String(decoding: data, as: UTF8.self)
    }
}
