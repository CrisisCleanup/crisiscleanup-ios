// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension FieldDynamicValue {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> FieldDynamicValue {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toFieldDynamicValue()
	}

	struct Builder {
		var field: IncidentFormField
		var selectOptions: [String: String]
		var childKeys: Set<String>
		var nestLevel: Int
		var dynamicValue: DynamicValue
		var workTypeStatus: WorkTypeStatus

		fileprivate init(original: FieldDynamicValue) {
			self.field = original.field
			self.selectOptions = original.selectOptions
			self.childKeys = original.childKeys
			self.nestLevel = original.nestLevel
			self.dynamicValue = original.dynamicValue
			self.workTypeStatus = original.workTypeStatus
		}

		fileprivate func toFieldDynamicValue() -> FieldDynamicValue {
			return FieldDynamicValue(
				field,
				selectOptions,
				childKeys: childKeys,
				nestLevel: nestLevel,
				dynamicValue: dynamicValue,
				workTypeStatus: workTypeStatus
			)
		}
	}
}
