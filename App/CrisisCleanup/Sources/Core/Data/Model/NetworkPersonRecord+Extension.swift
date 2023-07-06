extension NetworkPersonContact {
    func asRecord() -> PersonContactRecord {
        PersonContactRecord(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile
        )
    }

    func asExternalModel() -> PersonContact {
        PersonContact(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile
        )
    }
}
