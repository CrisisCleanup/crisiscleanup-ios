struct WorksiteLocalImage: Equatable {
    let id: Int64
    let worksiteId: Int64
    let documentId: String
    let uri: String
    let tag: String
    let rotateDegrees: Int

    init(
        id: Int64,
        worksiteId: Int64,
        documentId: String,
        uri: String,
        tag: String,
        rotateDegrees: Int = 0
    ) {
        self.id = id
        self.worksiteId = worksiteId
        self.documentId = documentId
        self.uri = uri
        self.tag = tag
        self.rotateDegrees = rotateDegrees
    }
}
