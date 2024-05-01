enum ImageCategory: String, Identifiable, CaseIterable {
    case before,
         after

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .before: return "before"
        case .after: return "after"
        }
    }
}

private let imageCategoryLookup = ImageCategory.allCases.associateBy { $0.literal }

public struct CaseImage: Equatable {
    let id: Int64
    let isNetworkImage: Bool
    let thumbnailUri: String
    let imageUri: String
    let tag: String
    let title: String
    let rotateDegrees: Int

    let category: ImageCategory
    let isAfter: Bool

    var imageName: String { imageUri.lastPath }

    init(
        id: Int64,
        isNetworkImage: Bool,
        thumbnailUri: String,
        imageUri: String,
        tag: String,
        title: String = "",
        rotateDegrees: Int = 0
    ) {
        self.id = id
        self.isNetworkImage = isNetworkImage
        self.thumbnailUri = thumbnailUri
        self.imageUri = imageUri
        self.tag = tag
        self.title = title
        self.rotateDegrees = rotateDegrees

        category = imageCategoryLookup[tag.lowercased()] ?? ImageCategory.before
        isAfter = category == ImageCategory.after
    }
}

extension NetworkImage {
    func asCaseImage() -> CaseImage {
        CaseImage(
            id: id,
            isNetworkImage: true,
            thumbnailUri: thumbnailUrl,
            imageUri: imageUrl,
            tag: tag,
            title: title,
            rotateDegrees: rotateDegrees
        )
    }
}

extension WorksiteLocalImage {
    func asCaseImage() -> CaseImage {
        CaseImage(
            id: id,
            isNetworkImage: false,
            thumbnailUri: uri,
            imageUri: uri,
            tag: tag,
            rotateDegrees: rotateDegrees
        )
    }
}
