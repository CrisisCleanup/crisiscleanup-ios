import Foundation

private let releaseDaysThreshold = 30.days

// sourcery: copyBuilder
public struct WorkType {
    let id: Int64
    let createdAt: Date?
    let orgClaim: Int64?
    let nextRecurAt: Date?
    let phase: Int?
    let recur: String?
    let statusLiteral: String
    let workTypeLiteral: String

    // sourcery:begin: skipCopy
    lazy var isClaimed: Bool = { orgClaim != nil }()
    lazy var status: WorkTypeStatus = { statusFromLiteral(statusLiteral) }()
    lazy var statusClaim = { WorkTypeStatusClaim(status, isClaimed) }()
    lazy var workType: WorkTypeType = { typeFromLiteral(workTypeLiteral) }()

    var isReleaseEligible: Bool {
        if let at = createdAt {
            return Date.now.addingTimeInterval(releaseDaysThreshold) > at
        }
        return false
    }
    // sourcery:end

    init(
        id: Int64,
        createdAt: Date? = nil,
        orgClaim: Int64? = nil,
        nextRecurAt: Date? = nil,
        phase: Int? = nil,
        recur: String? = nil,
        statusLiteral: String,
        workTypeLiteral: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.orgClaim = orgClaim
        self.nextRecurAt = nextRecurAt
        self.phase = phase
        self.recur = recur
        self.statusLiteral = statusLiteral
        self.workTypeLiteral = workTypeLiteral
    }
}

public enum WorkTypeStatus: String, Identifiable, CaseIterable {
    case Unknown
    case OpenAssigned
    case OpenUnassigned
    case OpenPartiallyCompleted
    case OpenNeedsFollowUp
    case OpenUnresponsive
    case ClosedCompleted
    case ClosedIncomplete
    case ClosedOutOfScope
    case ClosedDoneByOthers
    case ClosedNoHelpWanted
    case ClosedDuplicate
    case ClosedRejected

    public var id: String { rawValue }

    var literal: String {
        switch self {
        case .Unknown: return "unknown"
        case .OpenAssigned: return "open_assigned"
        case .OpenUnassigned: return "open_unassigned"
        case .OpenPartiallyCompleted: return "open_partially-completed"
        case .OpenNeedsFollowUp: return "open_needs-follow-up"
        case .OpenUnresponsive: return "open_unresponsive"
        case .ClosedCompleted: return "closed_completed"
        case .ClosedIncomplete: return "closed_incomplete"
        case .ClosedOutOfScope: return "closed_out-of-scope"
        case .ClosedDoneByOthers: return "closed_done-by-others"
        case .ClosedNoHelpWanted: return "closed_no-help-wanted"
        case .ClosedDuplicate: return "closed_duplicate"
        case .ClosedRejected: return "closed_rejected"
        }
    }
}


fileprivate let literalStatusLookup = WorkTypeStatus.allCases.associateBy{ $0.literal }
func statusFromLiteral(_ literal: String) -> WorkTypeStatus { literalStatusLookup[literal] ?? WorkTypeStatus.Unknown
}

public struct WorkTypeStatusClaim {
    let status: WorkTypeStatus
    let isClaimed: Bool

    init(
        _ status: WorkTypeStatus,
        _ isClaimed: Bool
    ) {
        self.status = status
        self.isClaimed = isClaimed
    }

    static func getType(type: String) -> WorkTypeType {
        return typeFromLiteral(type)
    }

    static func make(_ status: String, _ orgId: Int64?) -> WorkTypeStatusClaim {
        WorkTypeStatusClaim(
            statusFromLiteral(status),
            orgId != nil
        )
    }
}

private func typeFromLiteral(_ type: String) -> WorkTypeType {
    switch type.lowercased() {
    case "ash": return WorkTypeType.Ash
    case "animal_services": return WorkTypeType.AnimalServices
    case "catchment_gutters": return WorkTypeType.CatchmentGutters
    case "construction_consultation": return WorkTypeType.ConstructionConsultation
    case "core_relief_items": return WorkTypeType.CoreReliefItems
    case "demolition": return WorkTypeType.Demolition
    case "debris": return WorkTypeType.Debris
    case "deferred_maintenance": return WorkTypeType.DeferredMaintenance
    case "domestic_services": return WorkTypeType.DomesticServices
    case "erosion": return WorkTypeType.Erosion
    case "escort": return WorkTypeType.Escort
    case "fence": return WorkTypeType.Fence
    case "fire": return WorkTypeType.Fire
    case "food": return WorkTypeType.Food
    case "landslide": return WorkTypeType.Landslide
    case "leak": return WorkTypeType.Leak
    case "meals": return WorkTypeType.Meals
    case "mold_remediation": return WorkTypeType.MoldRemediation
    case "muck_out": return WorkTypeType.MuckOut
    case "other": return WorkTypeType.Other
    case "oxygen": return WorkTypeType.Oxygen
    case "pipe": return WorkTypeType.Pipe
    case "ppe": return WorkTypeType.Ppe
    case "prescription": return WorkTypeType.Prescription
    case "rebuild_total": return WorkTypeType.RebuildTotal
    case "rebuild": return WorkTypeType.Rebuild
    case "retardant_cleanup": return WorkTypeType.RetardantCleanup
    case "shelter": return WorkTypeType.Shelter
    case "shopping": return WorkTypeType.Shopping
    case "smoke_damage": return WorkTypeType.SmokeDamage
    case "snow_ground": return WorkTypeType.SnowGround
    case "snow_roof": return WorkTypeType.SnowRoof
    case "structure": return WorkTypeType.Structure
    case "tarp": return WorkTypeType.Tarp
    case "temporary_housing": return WorkTypeType.TemporaryHousing
    case "trees_heavy_equipment": return WorkTypeType.TreesHeavyEquipment
    case "trees": return WorkTypeType.Trees
    case "water_bottles": return WorkTypeType.WaterBottles
    case "wellness_check": return WorkTypeType.WellnessCheck
    case "sandbagging": return WorkTypeType.Sandbagging
    case "chimney_capping": return WorkTypeType.ChimneyCapping
    default: return WorkTypeType.Unknown
    }
}

public enum WorkTypeType: String, Identifiable, CaseIterable {
    case AnimalServices
    case Ash
    case CatchmentGutters
    case ChimneyCapping
    case ConstructionConsultation
    case CoreReliefItems
    case Debris
    case DeferredMaintenance
    case Demolition
    case DomesticServices
    case Erosion
    case Escort
    case Favorite
    case Fence
    case Fire
    case Food
    case Important
    case Landslide
    case Leak
    case Meals
    case MoldRemediation
    case MuckOut
    case Other
    case Oxygen
    case Pipe
    case Ppe
    case Prescription
    case Rebuild
    case RebuildTotal
    case RetardantCleanup
    case Sandbagging
    case Shelter
    case Shopping
    case SmokeDamage
    case SnowGround
    case SnowRoof
    case Structure
    case Tarp
    case TemporaryHousing
    case Trees
    case TreesHeavyEquipment
    case Unknown
    case WaterBottles
    case WellnessCheck

    public var id: String { rawValue }
}
