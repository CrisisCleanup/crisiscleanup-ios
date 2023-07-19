import Foundation

struct WorksiteSnapshot: Codable, Equatable {
    let core: CoreSnapshot
    let flags: [FlagSnapshot]
    let notes: [NoteSnapshot]
    let workTypes: [WorkTypeSnapshot]

    /**
     * - Parameter noteIdLookup Local ID to network ID. Missing in map or non-positive network ID indicates not yet successfully synced to backend.
     */
    func getNewNetworkNotes(_ noteIdLookup: [Int64: Int64]) -> [(Int64, NetworkNote)] {
        return notes
            .filter { (noteIdLookup[$0.localId] ?? -1) <= 0 }
            .filter { $0.note.id <= 0 }
            .filter { $0.note.note.isNotBlank }
            .map { entry in
                let n = entry.note
                return (
                    entry.localId,
                    NetworkNote(
                        nil,
                        n.createdAt,
                        n.isSurvivor,
                        n.note
                    )
                )
            }
    }

    func matchingWorkTypeOrNil(_ workTypeLocalId: Int64) -> NetworkWorkType? {
        if let workType = workTypes.first(where: { $0.localId == workTypeLocalId }) {
            let w = workType.workType
            if w.id >= 0 {
                return NetworkWorkType(
                    id: w.id,
                    createdAt: w.createdAt,
                    orgClaim: w.orgClaim,
                    nextRecurAt: w.nextRecurAt,
                    phase: w.phase,
                    recur: w.recur,
                    status: w.status,
                    workType: w.workType
                )
            }
        }
        return nil
    }
}

// sourcery: copyBuilder
struct CoreSnapshot: Codable, Equatable {
    let id: Int64
    let address: String
    let autoContactFrequencyT: String
    let caseNumber: String
    let city: String
    let county: String
    let createdAt: Date?
    let email: String?
    let favoriteId: Int64?
    let formData: [String: DynamicValue]
    let incidentId: Int64
    // Keys to a work type in workTypes
    let keyWorkTypeId: Int64?
    let latitude: Double
    let longitude: Double
    let name: String
    let networkId: Int64
    let phone1: String
    let phone2: String
    let plusCode: String?
    let postalCode: String
    let reportedBy: Int64?
    let state: String
    let svi: Float?
    let updatedAt: Date?
    let what3Words: String?
    let isAssignedToOrgMember: Bool

    var networkFormData: [KeyDynamicValuePair] {
        formData.map {
            KeyDynamicValuePair($0.key, $0.value)
        }
    }

    var pointLocation: NetworkWorksiteFull.Location {
        NetworkWorksiteFull.Location(
            type: "Point",
            coordinates: [longitude, latitude]
        )
    }
}

// sourcery: copyBuilder
struct FlagSnapshot: Codable, Equatable {
    let localId: Int64
    let flag: Flag

    // sourcery: copyBuilder
    struct Flag: Codable, Equatable {
        let id: Int64
        let action: String
        let createdAt: Date
        let isHighPriority: Bool
        let notes: String
        let reasonT: String
        let reason: String
        let requestedAction: String
    }

    func asNetworkFlag() -> NetworkFlag {
        let f = flag
        return NetworkFlag(
            id: f.id > 0 ? f.id : nil,
            action: f.action.ifBlank { nil },
            createdAt: f.createdAt,
            isHighPriority: f.isHighPriority,
            notes: f.notes.ifBlank { nil },
            reasonT: f.reasonT,
            requestedAction: f.requestedAction.ifBlank { nil }
        )
    }
}

struct NoteSnapshot: Codable, Equatable {
    let localId: Int64
    let note: Note

    struct Note: Codable, Equatable {
        let id: Int64
        let createdAt: Date
        let isSurvivor: Bool
        let note: String
    }
}

// sourcery: copyBuilder
struct WorkTypeSnapshot: Codable, Equatable {
    let localId: Int64
    let workType: WorkType

    // sourcery: copyBuilder, skipCopyInit
    struct WorkType: Codable, Equatable {
        let id: Int64
        let createdAt: Date?
        let orgClaim: Int64?
        let nextRecurAt: Date?
        let phase: Int?
        let recur: String?
        let status: String
        let workType: String

        init(
            id: Int64,
            status: String,
            workType: String,
            createdAt: Date? = nil,
            orgClaim: Int64? = nil,
            nextRecurAt: Date? = nil,
            phase: Int? = nil,
            recur: String? = nil
        ) {
            self.id = id
            self.status = status
            self.workType = workType
            self.createdAt = createdAt
            self.orgClaim = orgClaim
            self.nextRecurAt = nextRecurAt
            self.phase = phase
            self.recur = recur
        }

        func changeFrom(
            _ reference: WorkType,
            _ localId: Int64,
            _ changedAt: Date
        ) -> WorkTypeChange? {
            if workType.trim() != reference.workType.trim() {
                return nil
            }

            return WorkTypeChange(
                localId: localId,
                networkId: -1,
                workType: self,
                changedAt: changedAt,
                isClaimChange: orgClaim != reference.orgClaim,
                isStatusChange: status.trim() != reference.status.trim()
            )
        }
    }
}

// sourcery: copyBuilder
struct WorkTypeChange: Codable, Equatable {
    let localId: Int64
    let networkId: Int64
    let workType: WorkTypeSnapshot.WorkType
    let changedAt: Date
    let isClaimChange: Bool
    let isStatusChange: Bool

    var hasChange: Bool {
        isClaimChange || isStatusChange
    }
}
