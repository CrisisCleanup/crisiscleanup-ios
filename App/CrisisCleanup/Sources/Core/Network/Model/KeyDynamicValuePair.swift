public struct KeyDynamicValuePair: Codable, Equatable {
    let key: String
    let value: DynamicValue

    enum CodingKeys: String, CodingKey {
        case key = "field_key"
        case value = "field_value"
    }

    init(
        _ key: String,
        _ value: DynamicValue
    ) {
        self.key = key
        self.value = value
    }
}

public struct DynamicValue: Codable, Equatable {
    let valueString: String
    let isBool: Bool
    let valueBool: Bool

    init(
        valueString: String,
        isBool: Bool = false,
        valueBool: Bool = false
    ) {
        self.valueString = valueString
        self.isBool = isBool
        self.valueBool = valueBool
    }

    init(_ valueString: String) {
        self.valueString = valueString
        isBool = false
        valueBool = false
    }

    init(_ valueBool: Bool) {
        self.valueString = ""
        isBool = true
        self.valueBool = valueBool
    }

    public init(from decoder: Decoder) throws {
        var s = ""
        var isB = false
        var b = false

        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            s = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            b = boolValue
            isB = true
        }

        self.valueString = s
        self.isBool = isB
        self.valueBool = b
    }

    var isBoolTrue: Bool { isBool && valueBool }

    func isBoolEqual(_ other: DynamicValue) -> Bool {
        isBool && other.isBool && valueBool == other.valueBool
    }

    func isStringEqual(_ other: DynamicValue) -> Bool {
        !isBool && !other.isBool && valueString.trim() == other.valueString.trim()
    }
}
