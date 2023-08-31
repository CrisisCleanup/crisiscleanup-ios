import Combine
import Foundation
import GRDB
import TestableCombinePublishers
import XCTest
@testable import CrisisCleanup

class IncidentOrganizationDaoTests: XCTestCase {
    private let orgA = testOrganization(11, "a"),
                orgB = testOrganization(12, "b"),
                orgC = testOrganization(13, "c"),
                orgD = testOrganization(14, "d"),
                orgE = testOrganization(15, "e")

    private let contactGee = testPersonContactRecord(55, firstName: "G"),
                contactAch = testPersonContactRecord(56, firstName: "H"),
                contactEye = testPersonContactRecord(57, firstName: "I"),
                contactJay = testPersonContactRecord(58, firstName: "J"),
                contactKey = testPersonContactRecord(59, firstName: "K"),
                contactEle = testPersonContactRecord(60, firstName: "L"),
                contactEmm = testPersonContactRecord(61, firstName: "M"),
                contactEyn = testPersonContactRecord(62, firstName: "N"),
                contactOhw = testPersonContactRecord(63, firstName: "O")

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var organizationDao: IncidentOrganizationDao!

    override func setUp() async throws {
        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        organizationDao = IncidentOrganizationDao(appDb)

        try await seedInitialDb()
    }

    private func seedInitialDb() async throws {
        let orgRecords = [
            orgA,
            orgB,
            orgC,
            orgD,
            orgE,
        ]
        let contactRecords = [
            contactGee,
            contactAch,
            contactEye,
            contactJay,
            contactKey,
            contactEle,
            contactEmm,
            contactEyn,
            contactOhw,
        ]
        try await organizationDao.saveOrganizations(orgRecords, contactRecords)

        let orgContacts = [
            organizationContact(orgA.id, contactGee.id),
            organizationContact(orgA.id, contactAch.id),
            organizationContact(orgB.id, contactEye.id),
            organizationContact(orgB.id, contactJay.id),
            organizationContact(orgB.id, contactKey.id),
            organizationContact(orgC.id, contactEle.id),
            organizationContact(orgD.id, contactEmm.id),
            organizationContact(orgA.id, contactEyn.id),
            organizationContact(orgB.id, contactOhw.id),
        ]
        let orgAffiliates = [
            organizationAffiliate(orgA.id, orgB.id),
            organizationAffiliate(orgA.id, orgD.id),
            organizationAffiliate(orgB.id, orgC.id),
            organizationAffiliate(orgB.id, orgE.id),
            organizationAffiliate(orgC.id, orgE.id),
        ]
        try await dbQueue.write { db in
            for record in orgContacts {
                try record.insert(db)
            }
            for record in orgAffiliates {
                try record.insert(db)
            }
        }
    }

    func testSaveOrganizationAndReferences() async throws {
        let organizations = [orgA, orgB]
        let organizationContacts = [
            organizationContact(orgA.id, contactGee.id),
            organizationContact(orgA.id, contactJay.id),
            organizationContact(orgB.id, contactEmm.id),
        ]
        let organizationAffiliates = [
            organizationAffiliate(orgA.id, orgD.id),
            organizationAffiliate(orgA.id, orgC.id),
        ]

        try await organizationDao.saveOrganizationReferences(
            organizations,
            organizationContacts,
            organizationAffiliates
        )

        organizationDao.streamOrganizations()
            .map { $0.map { p in p.asExternalModel() } }
            .collect(1)
            .expect([[
                IncidentOrganization(
                    id: orgA.id,
                    name: "a",
                    primaryContacts: [
                        contactGee.asExternalModel(),
                        contactJay.asExternalModel(),
                    ],
                    affiliateIds: Set([orgC.id, orgD.id])
                ),
                IncidentOrganization(
                    id: orgB.id,
                    name: "b",
                    primaryContacts: [],
                    affiliateIds: []
                ),
                IncidentOrganization(
                    id: orgC.id,
                    name: "c",
                    primaryContacts: [contactEle.asExternalModel()],
                    affiliateIds: Set([orgE.id])
                ),
                IncidentOrganization(
                    id: orgD.id,
                    name: "d",
                    primaryContacts: [contactEmm.asExternalModel()],
                    affiliateIds: []
                ),
                IncidentOrganization(
                    id: orgE.id,
                    name: "e",
                    primaryContacts: [],
                    affiliateIds: []
                ),
            ]])
            .waitForExpectations(timeout: 0.1)
    }
}

private func testOrganization(
    _ id: Int64,
    _ name: String
) -> IncidentOrganizationRecord {
    IncidentOrganizationRecord(id: id, name: name, primaryLocation: nil, secondaryLocation: nil)
}

private func testPersonContactRecord(
    _ id: Int64,
    firstName: String = "first",
    lastName: String = "last",
    email: String = "",
    phone: String = ""
) -> PersonContactRecord {
    PersonContactRecord(id: id, firstName: firstName, lastName: lastName, email: email, mobile: phone)
}

private func organizationContact(
    _ id: Int64,
    _ contactId: Int64
) -> OrganizationToPrimaryContactRecord {
    OrganizationToPrimaryContactRecord(id: id, contactId: contactId)
}

private func organizationAffiliate(
    _ id: Int64,
    _ affiliateId: Int64
) -> OrganizationAffiliateRecord {
    OrganizationAffiliateRecord(id: id, affiliateId: affiliateId)
}
