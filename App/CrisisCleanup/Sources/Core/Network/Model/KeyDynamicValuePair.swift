public struct KeyDynamicValuePair: Codable, Equatable {
    let key: String
    let value: DynamicValue

    enum CodingKeys: String, CodingKey {
        case key = "field_key"
        case value = "field_value"
    }
}

// TODO: Test @Serializable(DynamicValueSerializer::class)
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

    var isBoolTrue: Bool { isBool && valueBool }

    func isBoolEqual(other: DynamicValue) -> Bool {
        isBool && other.isBool && valueBool == other.valueBool
    }

    func isStringEqual(other: DynamicValue) -> Bool {
        !isBool && !other.isBool && valueString.trim() == other.valueString.trim()
    }
}
