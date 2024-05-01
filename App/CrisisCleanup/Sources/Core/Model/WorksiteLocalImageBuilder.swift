// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension WorksiteLocalImage {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteLocalImage {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteLocalImage()
	}

	struct Builder {
		var id: Int64
		var worksiteId: Int64
		var documentId: String
		var uri: String
		var tag: String
		var rotateDegrees: Int

		fileprivate init(original: WorksiteLocalImage) {
			self.id = original.id
			self.worksiteId = original.worksiteId
			self.documentId = original.documentId
			self.uri = original.uri
			self.tag = original.tag
			self.rotateDegrees = original.rotateDegrees
		}

		fileprivate func toWorksiteLocalImage() -> WorksiteLocalImage {
			return WorksiteLocalImage(
				id: id,
				worksiteId: worksiteId,
				documentId: documentId,
				uri: uri,
				tag: tag,
				rotateDegrees: rotateDegrees
			)
		}
	}
}
