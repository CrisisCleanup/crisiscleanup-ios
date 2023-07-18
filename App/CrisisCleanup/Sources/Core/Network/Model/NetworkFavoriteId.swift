struct NetworkFavoriteId: Codable {
    let favoriteId: Int64

    enum CodingKeys: String, CodingKey {
        case favoriteId = "favorite_id"
    }
}
