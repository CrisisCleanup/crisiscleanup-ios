// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension FieldDynamicValue {
	// A default style constructor for the .copy fn to use
	init(
		field: IncidentFormField,
		selectOptions: [String: String],
		childKeys: Set<String>,
		nestLevel: Int,
		dynamicValue: DynamicValue,
		breakGlass: FieldEditProperties,
		workTypeStatus: WorkTypeStatus,
		isWorkTypeGroup: Bool,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.field = field
		self.selectOptions = selectOptions
		self.childKeys = childKeys
		self.nestLevel = nestLevel
		self.dynamicValue = dynamicValue
		self.breakGlass = breakGlass
		self.workTypeStatus = workTypeStatus
		self.isWorkTypeGroup = isWorkTypeGroup
	}

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
		var breakGlass: FieldEditProperties
		var workTypeStatus: WorkTypeStatus
		var isWorkTypeGroup: Bool

		fileprivate init(original: FieldDynamicValue) {
			self.field = original.field
			self.selectOptions = original.selectOptions
			self.childKeys = original.childKeys
			self.nestLevel = original.nestLevel
			self.dynamicValue = original.dynamicValue
			self.breakGlass = original.breakGlass
			self.workTypeStatus = original.workTypeStatus
			self.isWorkTypeGroup = original.isWorkTypeGroup
		}

		fileprivate func toFieldDynamicValue() -> FieldDynamicValue {
			return FieldDynamicValue(
				field: field,
				selectOptions: selectOptions,
				childKeys: childKeys,
				nestLevel: nestLevel,
				dynamicValue: dynamicValue,
				breakGlass: breakGlass,
				workTypeStatus: workTypeStatus,
				isWorkTypeGroup: isWorkTypeGroup
			)
		}
	}
}
