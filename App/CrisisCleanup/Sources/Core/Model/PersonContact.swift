public struct PersonContact {
    let id: Int64
    let fullName: String
    let email: String
    let mobile: String

    init(
        id: Int64,
        firstName: String,
        lastName: String,
        email: String,
        mobile: String
    ) {
        self.id = id
        fullName = "\(firstName) \(lastName)".trim()
        self.email = email
        self.mobile = mobile
    }
}
