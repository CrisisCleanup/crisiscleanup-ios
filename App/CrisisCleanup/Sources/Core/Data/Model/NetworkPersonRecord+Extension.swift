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

    func asRecords() -> PersonContactRecords {
        let organizationEntity = IncidentOrganizationRecord(
            id: organization!.id,
            name: organization!.name,
            primaryLocation: nil,
            secondaryLocation: nil
        )
        let personContact = asRecord()
        let personToOrganization = OrganizationToPrimaryContactRecord(
            id: organization!.id,
            contactId: id
        )
        return PersonContactRecords(
            organization: organizationEntity,
            organizationAffiliates: organization!.affiliates,
            personContact: personContact,
            personToOrganization: personToOrganization
        )
    }
}

struct PersonContactRecords {
    let organization: IncidentOrganizationRecord
    let organizationAffiliates: [Int64]
    let personContact: PersonContactRecord
    let personToOrganization: OrganizationToPrimaryContactRecord
}
