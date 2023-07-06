// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension FormFieldNode {
	// A default style constructor for the .copy fn to use
	init(
		formField: IncidentFormField,
		children: [FormFieldNode],
		options: [String: String],
		fieldKey: String,
		parentKey: String,
		isRootNode: Bool,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.formField = formField
		self.children = children
		self.options = options
		self.fieldKey = fieldKey
		self.parentKey = parentKey
		self.isRootNode = isRootNode
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> FormFieldNode {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toFormFieldNode()
	}

	struct Builder {
		var formField: IncidentFormField
		var children: [FormFieldNode]
		var options: [String: String]
		var fieldKey: String
		var parentKey: String
		var isRootNode: Bool

		fileprivate init(original: FormFieldNode) {
			self.formField = original.formField
			self.children = original.children
			self.options = original.options
			self.fieldKey = original.fieldKey
			self.parentKey = original.parentKey
			self.isRootNode = original.isRootNode
		}

		fileprivate func toFormFieldNode() -> FormFieldNode {
			return FormFieldNode(
				formField: formField,
				children: children,
				options: options,
				fieldKey: fieldKey,
				parentKey: parentKey,
				isRootNode: isRootNode
			)
		}
	}
}
