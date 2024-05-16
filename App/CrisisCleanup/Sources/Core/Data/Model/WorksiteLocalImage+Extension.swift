extension WorksiteLocalImage {
    func asRecord() -> WorksiteLocalImageRecord {
        WorksiteLocalImageRecord(
            id: id > 0 ? id : nil,
            worksiteId: worksiteId,
            localDocumentId: documentId,
            uri: uri,
            tag: tag,
            rotateDegrees: rotateDegrees
        )
    }
}
