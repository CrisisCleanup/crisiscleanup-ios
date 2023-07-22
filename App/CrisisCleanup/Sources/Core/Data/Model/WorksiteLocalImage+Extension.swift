extension WorksiteLocalImage {
    func asRecord() -> WorksiteLocalImageRecord {
        WorksiteLocalImageRecord(
            id: id,
            worksiteId: worksiteId,
            localDocumentId: documentId,
            uri: uri,
            tag: tag,
            rotateDegrees: rotateDegrees
        )
    }
}
