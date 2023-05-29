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
