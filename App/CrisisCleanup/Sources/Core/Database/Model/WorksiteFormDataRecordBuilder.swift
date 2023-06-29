// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension WorksiteFormDataRecord {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64?,
		worksiteId: Int64,
		fieldKey: String,
		isBoolValue: Bool,
		valueString: String,
		valueBool: Bool,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.worksiteId = worksiteId
		self.fieldKey = fieldKey
		self.isBoolValue = isBoolValue
		self.valueString = valueString
		self.valueBool = valueBool
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteFormDataRecord {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteFormDataRecord()
	}

	struct Builder {
		var id: Int64?
		var worksiteId: Int64
		var fieldKey: String
		var isBoolValue: Bool
		var valueString: String
		var valueBool: Bool

		fileprivate init(original: WorksiteFormDataRecord) {
			self.id = original.id
			self.worksiteId = original.worksiteId
			self.fieldKey = original.fieldKey
			self.isBoolValue = original.isBoolValue
			self.valueString = original.valueString
			self.valueBool = original.valueBool
		}

		fileprivate func toWorksiteFormDataRecord() -> WorksiteFormDataRecord {
			return WorksiteFormDataRecord(
				id: id,
				worksiteId: worksiteId,
				fieldKey: fieldKey,
				isBoolValue: isBoolValue,
				valueString: valueString,
				valueBool: valueBool
			)
		}
	}
}
