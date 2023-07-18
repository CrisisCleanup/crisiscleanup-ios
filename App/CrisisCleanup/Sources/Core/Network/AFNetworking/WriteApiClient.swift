import Foundation

class WriteApiClient: CrisisCleanupWriteApi {
    let networkClient: AFNetworkingClient
    let requestProvider: NetworkRequestProvider

    // TODO: Confirm formatting is as expected
    private let dateFormatter: ISO8601DateFormatter

    private let networkError: Error

    init(
        networkRequestProvider: NetworkRequestProvider,
        accountDataRepository: AccountDataRepository,
        authApiClient: CrisisCleanupAuthApi,
        authEventBus: AuthEventBus,
        appEnv: AppEnv
    ) {
        self.networkClient = AFNetworkingClient(
            appEnv,
            interceptor: AccessTokenInterceptor(
                accountDataRepository: accountDataRepository,
                authApiClient: authApiClient,
                authEventBus: authEventBus
            )
        )
        requestProvider = networkRequestProvider

        dateFormatter = ISO8601DateFormatter()

        networkError = GenericError("Network error")
    }

    func saveWorksite(
        _ modifiedAt: Date,
        _ syncUuid: String,
        _ worksite: NetworkWorksitePush
    ) async throws -> NetworkWorksiteFull {
        let request = worksite.id == nil
        ? requestProvider.newWorksite
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: modifiedAt),
                "ccu-sync-uuid": syncUuid
            ])
            .setBody(worksite)
        : requestProvider.updateWorksite
            .addPaths("\(worksite.id!)")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: modifiedAt),
                "ccu-sync-uuid": syncUuid
            ])
            .setBody(worksite)

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorksiteFull.self
        )
        if let result = response.value {
            return result
        }
        throw response.error ?? networkError
    }

    func favoriteWorksite(_ createdAt: Date, _ worksiteId: Int64) async throws -> NetworkType {
        let request = requestProvider.favorite
            .addPaths("\(worksiteId)", "favorite")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(networkTypeFavorite)

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkType.self
        )
        if let result = response.value {
            return result
        }
        throw response.error ?? networkError
    }

    func unfavoriteWorksite(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ favoriteId: Int64
    ) async throws {
        let request = requestProvider.unfavorite
            .addPaths("\(worksiteId)", "favorite")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(NetworkFavoriteId(favoriteId: favoriteId))

        let response = await networkClient.callbackContinue(request)
        if let error = response.error {
            throw error
        }
    }

    func addFlag(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ flag: NetworkFlag
    ) async throws -> NetworkFlag {
        let request = requestProvider.addFlag
            .addPaths("\(worksiteId)", "flags")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(flag)

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkFlag.self
        )
        if let result = response.value {
            return result
        }
        throw response.error ?? networkError
    }

    func deleteFlag(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ flagId: Int64
    ) async throws {
        let request = requestProvider.unfavorite
            .addPaths("\(worksiteId)", "flags")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(NetworkFlagId(flagId: flagId))

        let response = await networkClient.callbackContinue(request)
        if let error = response.error {
            throw error
        }
    }

    func addNote(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ note: String
    ) async throws -> NetworkNote {
        let request = requestProvider.addFlag
            .addPaths("\(worksiteId)", "notes")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(NetworkNoteNote(note: note, createdAt: createdAt))

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkNote.self
        )
        if let result = response.value {
            return result
        }
        throw response.error ?? networkError
    }

    func updateWorkTypeStatus(
        _ createdAt: Date,
        _ workTypeId: Int64,
        _ status: String
    ) async throws -> NetworkWorkType {
        let request = requestProvider.updateWorkTypeStatus
            .addPaths("\(workTypeId)")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(NetworkWorkTypeStatus(status: status))

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkWorkType.self
        )
        if let result = response.value {
            return result
        }
        throw response.error ?? networkError
    }

    func claimWorkTypes(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ workTypes: [String]
    ) async throws {
        let request = requestProvider.claimWorkTypes
            .addPaths("\(worksiteId)", "claim")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(NetworkWorkTypeTypes(workTypes: workTypes))

        let response = await networkClient.callbackContinue(request)
        if let error = response.error {
            throw error
        }
    }

    func unclaimWorkTypes(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ workTypes: [String]
    ) async throws {
        let request = requestProvider.unclaimWorkTypes
            .addPaths("\(worksiteId)", "unclaim")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(NetworkWorkTypeTypes(workTypes: workTypes))

        let response = await networkClient.callbackContinue(request)
        if let error = response.error {
            throw error
        }
    }

    func requestWorkTypes(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ workTypes: [String],
        _ reason: String
    ) async throws {
        let request = requestProvider.requestWorkTypes
            .addPaths("\(worksiteId)", "request_take")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(NetworkWorkTypeChangeRequest(workTypes: workTypes, reason: reason))

        let response = await networkClient.callbackContinue(request)
        if let error = response.error {
            throw error
        }
    }

    func releaseWorkTypes(
        _ createdAt: Date,
        _ worksiteId: Int64,
        _ workTypes: [String],
        _ reason: String
    ) async throws {
        let request = requestProvider.releaseWorkTypes
            .addPaths("\(worksiteId)", "release")
            .addHeaders([
                "ccu-created-at": dateFormatter.string(from: createdAt)
            ])
            .setBody(NetworkWorkTypeChangeRelease(workTypes: workTypes, reason: reason))

        let response = await networkClient.callbackContinue(request)
        if let error = response.error {
            throw error
        }
    }

    func deleteFile(_ worksiteId: Int64, _ file: Int64) async throws {
        let request = requestProvider.deleteFile
            .addPaths("\(worksiteId)", "files")
            .setBody(NetworkFilePush(file: file))

        let response = await networkClient.callbackContinue(request)
        if let error = response.error {
            throw error
        }
    }

    func startFileUpload(_ fileName: String, _ contentType: String) async throws -> NetworkFileUpload {
        let request = requestProvider.startFileUpload
            .setForm(NetworkFileUploadPayload(fileName: fileName, contentType: contentType))

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkFileUpload.self
        )
        if let result = response.value {
            return result
        }
        throw response.error ?? networkError
    }

//    func uploadFile(
//        url: String,
//        fields: FileUploadFields,
//        file: File,
//        mimeType: String
//    ) async {
//        let mediaType = mimeType.toMediaTypeOrnil()
//        let requestFile = file.asRequestBody(mediaType)
//        let partFile = MultipartBody.Part.createFormData("file", file.name, requestFile)
//        let parts = fields.asPartMap()
//        fileUploadApi.uploadFile(url, parts, partFile)
//    }

    func addFileToWorksite(
        _ worksiteId: Int64,
        _ file: Int64,
        _ tag: String
    ) async throws -> NetworkFile {
        let request = requestProvider.addUploadedFile
            .addPaths("\(worksiteId)", "files")
            .setBody(NetworkFilePush(file: file, tag: tag))

        let response = await networkClient.callbackContinue(
            requestConvertible: request,
            type: NetworkFile.self
        )
        if let result = response.value {
            return result
        }
        throw response.error ?? networkError
    }

    func shareWorksite(
        _ worksiteId: Int64,
        _ emails: [String],
        _ phoneNumbers: [String],
        _ shareMessage: String,
        _ noClaimReason: String?
    ) async throws {
        let request = requestProvider.shareWorksite
            .addPaths("\(worksiteId)", "share")
            .setBody(NetworkShareDetails(
                emails: emails,
                phoneNumbers: phoneNumbers,
                shareMessage: shareMessage,
                noClaimReason: noClaimReason?.isNotBlank == true ? noClaimReason : nil
            ))

        let response = await networkClient.callbackContinue(request)
        if let error = response.error {
            throw error
        }
    }
}
