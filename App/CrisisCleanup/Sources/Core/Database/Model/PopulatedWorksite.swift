import Foundation
import GRDB

struct PopulatedWorksite: Equatable, Decodable, FetchableRecord {
    let worksiteRoot: WorksiteRootRecord
    let worksite: WorksiteRecord
    let workTypes: [WorkTypeRecord]

    func asExternalModel() -> Worksite {
        Worksite.from(worksiteRoot, worksite, workTypes)
    }
}

struct WorksiteLocalModifiedAt: Equatable, Decodable, FetchableRecord {
    let id: Int64
    let networkId: Int64
    let localModifiedAt: Date
    let isLocalModified: Bool
}

struct PopulatedLocalWorksite: Equatable, Decodable, FetchableRecord {
    struct NetworkFileInfo: Equatable, Decodable {
        let networkFile: NetworkFileRecord
        let networkFileLocalImage: NetworkFileLocalImageRecord?
    }
    let worksiteRoot: WorksiteRootRecord
    let worksite: WorksiteRecord
    let worksiteFlags: [WorksiteFlagRecord]
    let worksiteFormData: [WorksiteFormDataRecord]
    let worksiteNotes: [WorksiteNoteRecord]
    let workTypes: [WorkTypeRecord]
    let worksiteWorkTypeRequests: [WorkTypeRequestRecord]
    let networkFiles: [NetworkFileInfo]
    let worksiteLocalImages: [WorksiteLocalImageRecord]

    func asExternalModel(
        _ orgId: Int64,
        _ translator: KeyTranslator? = nil
    ) -> LocalWorksite {
        let keyWorkType = workTypes
            .first(where: {
                $0.workType == worksite.keyWorkTypeType
            })?.asExternalModel()
        let formDataLookup = worksiteFormData.associate { ($0.fieldKey, $0.asExternalModel()) }
        let files = networkFiles.map { $0.networkFile }
        let networkFileLocalImages = networkFiles.compactMap { $0.networkFileLocalImage }
        let localFileImageLookup = networkFileLocalImages.associateBy { $0.id }
        let hasImagesPendingDelete = networkFileLocalImages.first { $0.isDeleted } != nil
        return LocalWorksite(
            worksite: Worksite(
                id: worksite.id!,
                address: worksite.address,
                autoContactFrequencyT: worksite.autoContactFrequencyT ?? "",
                caseNumber: worksite.caseNumber,
                city: worksite.city,
                county: worksite.county,
                createdAt: worksite.createdAt,
                email: worksite.email,
                favoriteId: worksite.favoriteId,
                files: files
                    .filter { localFileImageLookup[$0.id]?.isDeleted != true }
                    .filter { $0.fullUrl?.isNotBlank == true }
                    .map {
                        let rotateDegrees = localFileImageLookup[$0.id]?.rotateDegrees ?? 0
                        return $0.asImageModel(rotateDegrees)
                    }
                ,
                flags: worksiteFlags.map { $0.asExternalModel(translator) },
                formData: formDataLookup,
                incidentId: worksite.incidentId,
                keyWorkType: keyWorkType,
                latitude: worksite.latitude,
                longitude: worksite.longitude,
                name: worksite.name,
                networkId: worksite.networkId,
                notes: worksiteNotes
                    .filter { $0.note.isNotBlank }
                    .sorted(by: { a, b in
                        if a.networkId == b.networkId {
                            return a.createdAt >= b.createdAt
                        }
                        return  {
                            if a.networkId < 0 { return true }
                            else if b.networkId < 0 { return false }
                            else { return a.networkId > b.networkId }
                        }()
                    })
                    .map { $0.asExternalModel() },
                phone1: worksite.phone1 ?? "",
                phone2: worksite.phone2 ?? "",
                postalCode: worksite.postalCode,
                reportedBy: worksite.reportedBy,
                state: worksite.state,
                svi: worksite.svi,
                updatedAt: worksite.updatedAt,
                workTypes: workTypes.map { $0.asExternalModel() },
                workTypeRequests: worksiteWorkTypeRequests
                    .filter { $0.byOrg == orgId }
                    .map { $0.asExternalModel() },
                isAssignedToOrgMember: worksiteRoot.isLocalModified ? worksite.isLocalFavorite : worksite.favoriteId != nil
            ),
            localImages: worksiteLocalImages.map { $0.asExternalModel() },
            localChanges: LocalChange(
                isLocalModified: worksiteRoot.isLocalModified || hasImagesPendingDelete ||
                worksiteLocalImages.isNotEmpty,
                localModifiedAt: worksiteRoot.localModifiedAt,
                syncedAt: worksiteRoot.syncedAt
            )
        )
    }
}

private let highPriorityFlagLiteral = WorksiteFlagType.highPriority.literal
private let duplicateFlagLiteral = WorksiteFlagType.duplicate.literal

struct PopulatedWorksiteMapVisual: Decodable, FetchableRecord {
    struct WorksiteMapVisualSubset : Decodable {
        let incidentId: Int64
        let latitude: Double
        let longitude: Double
        let keyWorkTypeType: String
        let keyWorkTypeOrgClaim: Int64?
        let keyWorkTypeStatus: String
        let favoriteId: Int64?

        // Filter fields
        let createdAt: Date?
        let isLocalFavorite: Bool
        let reportedBy: Int64?
        let svi: Double?
        let updatedAt: Date
    }

    let id: Int64
    let isLocalModified: Bool
    let worksite: WorksiteMapVisualSubset
    let workTypeCount: Int
    let worksiteFlags: [WorksiteFlagRecord]

    // For filtering
    let worksiteFormData: [WorksiteFormDataRecord]
    let workTypes: [WorkTypeRecord]

    func asExternalModel(_ isFilteredOut: Bool = false) -> WorksiteMapMark {
        WorksiteMapMark(
            id: id,
            incidentId: worksite.incidentId,
            latitude: worksite.latitude,
            longitude: worksite.longitude,
            statusClaim: WorkTypeStatusClaim.make(
                worksite.keyWorkTypeStatus,
                worksite.keyWorkTypeOrgClaim
            ),
            workType: WorkTypeStatusClaim.getType(type: worksite.keyWorkTypeType),
            workTypeCount: workTypeCount,
            // TODO: Account for unsynced local favorite as well
            isFavorite: worksite.favoriteId != nil,
            isHighPriority: worksiteFlags.contains {
                $0.isHighPriority == true ||
                $0.reasonT == highPriorityFlagLiteral
            },
            isDuplicate: worksiteFlags.contains {
                $0.reasonT == duplicateFlagLiteral
            },
            isFilteredOut: isFilteredOut
        )
    }
}

extension NetworkFileRecord {
    fileprivate func asImageModel(_ rotateDegrees: Int) -> NetworkImage {
        NetworkImage(
            id: id,
            createdAt: createdAt,
            title: title ?? "",
            thumbnailUrl: smallThumbnailUrl ?? "",
            imageUrl: fullUrl ?? "",
            tag: tag ?? "",
            rotateDegrees: rotateDegrees
        )
    }
}

extension WorksiteLocalImageRecord {
    fileprivate func asExternalModel() -> WorksiteLocalImage {
        WorksiteLocalImage(
            id: id!,
            worksiteId: worksiteId,
            documentId: localDocumentId,
            uri: uri,
            tag: tag,
            rotateDegrees: rotateDegrees
        )
    }
}

struct PopulatedWorksitePendingSync: Equatable, Decodable, FetchableRecord {
    let id: Int64
    let caseNumber: String
    let incidentId: Int64
    let networkId: Int64

    func asExternalModel() -> WorksitePendingSync {
        WorksitePendingSync(
            id: id,
            caseNumber: caseNumber,
            incidentId: incidentId,
            networkId: networkId
        )
    }
}
