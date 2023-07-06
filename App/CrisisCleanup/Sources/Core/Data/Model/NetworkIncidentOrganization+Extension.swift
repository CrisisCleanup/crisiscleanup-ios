extension NetworkIncidentOrganization {
    func asRecord() -> IncidentOrganizationRecord {
        IncidentOrganizationRecord(
            id: id,
            name: name
        )
    }

    func primaryContactCrossReferences() -> [OrganizationToPrimaryContactRecord] {
        primaryContacts.map { OrganizationToPrimaryContactRecord(id: id, contactId: $0.id) }
    }

    func affiliateOrganizationCrossReferences() -> [OrganizationAffiliateRecord] {
        affiliates.map { OrganizationAffiliateRecord(id: id, affiliateId: $0) }
    }
}


fileprivate func flatten2DArray<T>(_ aa: [[T]]) -> [T] {
    Array(aa.joined())
}

extension Array where Element == NetworkIncidentOrganization {
    func asRecords(
        getContacts: Bool,
        getReferences: Bool
    ) -> OrganizationRecords {
        let organizations = map { $0.asRecord() }
        let primaryContacts = getContacts ? flatten2DArray(map { $0.primaryContacts.map { contact in contact.asRecord() } }) : []
        let organizationToContacts = getReferences ? flatten2DArray( map {$0.primaryContactCrossReferences() }) : []
        let organizationAffiliates = getReferences ? flatten2DArray(map { $0.affiliateOrganizationCrossReferences() }) : []
        return OrganizationRecords(
            organizations: organizations,
            primaryContacts: primaryContacts,
            organizationToContacts: organizationToContacts,
            orgAffiliates: organizationAffiliates
        )
    }
}

struct OrganizationRecords {
    let organizations: [IncidentOrganizationRecord]
    let primaryContacts: [PersonContactRecord]
    let organizationToContacts: [OrganizationToPrimaryContactRecord]
    let orgAffiliates: [OrganizationAffiliateRecord]
}
