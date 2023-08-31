public struct NetworkAppSupportInfo: Codable, Equatable {
    let minBuildVersion: Int64
    let title: String?
    let message: String
    let link: String?

    init(
        minBuildVersion: Int64,
        title: String? = nil,
        message: String,
        link: String? = nil
    ) {
        self.minBuildVersion = minBuildVersion
        self.title = title
        self.message = message.ifBlank {
            "A new version is available on the App Store.\nUpdate and enjoy :)"
        }
        self.link = link
    }
}
