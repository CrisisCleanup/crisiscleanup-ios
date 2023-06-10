import Foundation

struct NetworkFile: Codable, Equatable {
    let id: Int64
    let blogUrl: String?
    let createdAt: Date
    let file: Int64?
    let fileTypeT: String
    let fullUrl: String?
    let largeThumbnailUrl: String?
    let mimeContentType: String
    let notes: String?
    let smallThumbnailUrl: String?
    let tag: String?
    let title: String?
    let url: String

    enum CodingKeys: String, CodingKey {
        case id
        case blogUrl = "blog_url"
        case createdAt = "created_at"
        case file
        case fileTypeT = "file_type_t"
        case fullUrl = "full_url"
        case largeThumbnailUrl = "large_thumbnail_url"
        case mimeContentType = "mime_content_type"
        case notes
        case smallThumbnailUrl = "small_thumbnail_url"
        case tag
        case title
        case url
    }

    var isProfilePicture: Bool { fileTypeT == "fileTypes.user_profile_picture" }
}

public struct NetworkFilePush: Codable, Equatable {
    let file: Int64
    let tag: String?

    init(
        file: Int64,
        tag: String? = nil
    ) {
        self.file = file
        self.tag = tag
    }
}

public struct NetworkFileUpload: Codable, Equatable {
    let id: Int64
    let uploadProperties: FileUploadProperties

    enum CodingKeys: String, CodingKey {
        case id
        case uploadProperties = "presigned_post_url"
    }
}

public struct FileUploadProperties: Codable, Equatable {
    let url: String
    let fields: FileUploadFields
}

public struct FileUploadFields: Codable, Equatable {
    let key: String
    let algorithm: String
    let credential: String
    let date: String
    let policy: String
    let signature: String

    enum CodingKeys: String, CodingKey {
        case key
        case algorithm = "x-amz-algorithm"
        case credential = "x-amz-credential"
        case date = "x-amz-date"
        case policy
        case signature = "x-amz-signature"
    }

    internal func asMap() -> [String: String] {
        return [
            "key": key,
            "x-amz-algorithm": algorithm,
            "x-amz-credential": credential,
            "x-amz-date": date,
            "policy": policy,
            "x-amz-signature": signature
        ]
    }
}
