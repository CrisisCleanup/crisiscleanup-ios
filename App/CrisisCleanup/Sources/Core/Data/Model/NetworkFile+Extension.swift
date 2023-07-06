extension NetworkFile {
    func asRecord() -> NetworkFileRecord {
        NetworkFileRecord(
            id: id,
            createdAt: createdAt,
            fileId: file ?? 0,
            fileTypeT: fileTypeT,
            fullUrl: fullUrl,
            largeThumbnailUrl: largeThumbnailUrl,
            mimeContentType: mimeContentType,
            smallThumbnailUrl: smallThumbnailUrl,
            tag: tag,
            title: title,
            url: url
        )
    }
}
