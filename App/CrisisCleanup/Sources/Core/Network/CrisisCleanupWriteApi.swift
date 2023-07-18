import Foundation

public protocol CrisisCleanupWriteApi {
    func saveWorksite(
        _ modifiedAt: Date,
        _ syncUuid: String,
        _ worksite: NetworkWorksitePush
    ) async throws -> NetworkWorksiteFull

    func favoriteWorksite(_ createdAt: Date, _ worksiteId: Int64) async throws -> NetworkType
    func unfavoriteWorksite(_ createdAt: Date, _ worksiteId: Int64, _ favoriteId: Int64) async throws
    func addFlag(_ createdAt: Date, _ worksiteId: Int64, _ flag: NetworkFlag) async throws -> NetworkFlag
    func deleteFlag(_ createdAt: Date, _ worksiteId: Int64, _ flagId: Int64) async throws
    func addNote(_ createdAt: Date, _ worksiteId: Int64, _ note: String) async throws -> NetworkNote
    func updateWorkTypeStatus(
        _ createdAt: Date,
        _ workTypeId: Int64,
        _ status: String
    ) async throws -> NetworkWorkType

    func claimWorkTypes(_ createdAt: Date, _ worksiteId: Int64, _ workTypes: [String]) async throws
    func unclaimWorkTypes(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ workTypes: [String]
    ) async throws

    func requestWorkTypes(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ workTypes: [String],
        _ reason: String
    ) async throws

    func releaseWorkTypes(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ workTypes: [String],
        _ reason: String
    ) async throws

    func deleteFile(_ worksiteId: Int64, _ file: Int64) async throws

    func startFileUpload(
        _ fileName: String,
        _ contentType: String
    ) async throws -> NetworkFileUpload

    // TODO: When files are developed
//    func uploadFile(
//        _ url: String,
//        _ fields: FileUploadFields,
//        _ file: File,
//        _ mimeType: String
//    ) async throws

    func addFileToWorksite(
        _ worksiteId: Int64,
        _ file: Int64,
        _ tag: String
    ) async throws -> NetworkFile

    func shareWorksite(
        _ worksiteId: Int64,
        _ emails: [String],
        _ phoneNumbers: [String],
        _ shareMessage: String,
        _ noClaimReason: String?
    ) async throws
}
