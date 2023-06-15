extension NetworkIncident {
    func asExternalModel() -> Incident {
        return Incident(
            id: id,
            name: name,
            shortName: shortName,
            locationIds: [],
            activePhoneNumbers: activePhoneNumber ?? [String](),
            formFields: [],
            turnOnRelease: turnOnRelease,
            disasterLiteral: type
        )
    }
}
