extension IncidentOrganization{
    var contactList: [String] {
        primaryContacts.map {
            [
                $0.fullName,
                "(\(name))",
                "\($0.email) \($0.mobile)",
            ]
                .combineTrimText(" ")
        }
    }
}
