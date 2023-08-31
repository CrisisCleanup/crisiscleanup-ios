import Atomics
import Combine
import Foundation
import PhotosUI
import SwiftUI

class ViewCaseViewModel: ObservableObject, KeyTranslator {
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let accountDataRefresher: AccountDataRefresher
    private var editableWorksiteProvider: EditableWorksiteProvider
    private let transferWorkTypeProvider: TransferWorkTypeProvider
    private let localImageRepository: LocalImageRepository
    private let translator: KeyAssetTranslator
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let syncPusher: SyncPusher
    private let logger: AppLogger

    private let dataLoader: CaseEditorDataLoader

    let isValidWorksiteIds: Bool
    let incidentIdIn: Int64
    let worksiteIdIn: Int64

    private let localTranslate: (String) -> String

    @Published private(set) var headerTitle = ""
    @Published private(set) var subTitle = ""

    @Published private(set) var updatedAtText = ""

    @Published private(set) var isLoading = true

    @Published private(set) var isSyncing = false

    @Published private(set) var alert = false
    @Published private(set) var alertMessage = ""
    @Published var alertCount = 0

    let editableViewState = EditableView()

    private let isSavingWorksite = CurrentValueSubject<Bool, Never>(false)
    private let isSavingMedia = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSaving = false

    @Published private(set) var isPendingTransfer = false
    lazy var transferType: WorkTypeTransferType = { transferWorkTypeProvider.transferType }()

    @Published private(set) var syncingWorksiteImage: Int64 = 0

    private let isOrganizationsRefreshed = ManagedAtomic(false)
    private let organizationLookup: AnyPublisher<[Int64: IncidentOrganization], Never>

    private let editableWorksite: AnyPublisher<Worksite, Never>

    private let uiState: AnyPublisher<CaseEditorUiState, Never>
    @Published private(set) var caseData: CaseEditorCaseData? = nil

    var referenceWorksite: Worksite { caseData?.worksite ?? EmptyWorksite }

    @Published private(set) var workTypeProfile: WorkTypeProfile? = nil

    @Published private(set) var tabTitles: [ViewCaseTabs: String] = [
        .info: "",
        .photos: "",
        .notes: ""
    ]
    @Published private(set) var statusOptions: [WorkTypeStatus] = []
    @Published private(set) var beforeAfterPhotos: [ImageCategory: [CaseImage]] = [:]

    private let previousNoteCount = ManagedAtomic(0)

    var addImageCategory = ImageCategory.before
    @Published var cachingLocalImageCount = ObservableIntDictionary()
    private(set) var localImageCache = [String: UIImage]()

    private let nextRecurDateFormat: DateFormatter

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
        organizationsRepository: OrganizationsRepository,
        accountDataRefresher: AccountDataRefresher,
        incidentRefresher: IncidentRefresher,
        incidentBoundsProvider: IncidentBoundsProvider,
        locationManager: LocationManager,
        worksitesRepository: WorksitesRepository,
        languageRepository: LanguageTranslationsRepository,
        languageRefresher: LanguageRefresher,
        workTypeStatusRepository: WorkTypeStatusRepository,
        editableWorksiteProvider: EditableWorksiteProvider,
        transferWorkTypeProvider: TransferWorkTypeProvider,
        localImageRepository: LocalImageRepository,
        translator: KeyAssetTranslator,
        worksiteChangeRepository: WorksiteChangeRepository,
        syncPusher: SyncPusher,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory,
        incidentId: Int64,
        worksiteId: Int64
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.accountDataRefresher = accountDataRefresher
        self.editableWorksiteProvider = editableWorksiteProvider
        self.transferWorkTypeProvider = transferWorkTypeProvider
        self.localImageRepository = localImageRepository
        self.translator = translator
        self.worksiteChangeRepository = worksiteChangeRepository
        self.syncPusher = syncPusher
        logger = loggerFactory.getLogger("view-case")

        translationCount = translator.translationCount

        incidentIdIn = incidentId
        worksiteIdIn = worksiteId
        isValidWorksiteIds = incidentId > 0 && worksiteId > 0

        localTranslate = { phraseKey in
            editableWorksiteProvider.translate(key: phraseKey) ?? translator.t(phraseKey)
        }

        dataLoader = CaseEditorDataLoader(
            isCreateWorksite: false,
            incidentIdIn: incidentIdIn,
            accountDataRepository: accountDataRepository,
            incidentsRepository: incidentsRepository,
            incidentRefresher: incidentRefresher,
            incidentBoundsProvider: incidentBoundsProvider,
            locationManager: locationManager,
            worksitesRepository: worksitesRepository,
            worksiteChangeRepository: worksiteChangeRepository,
            keyTranslator: languageRepository,
            languageRefresher: languageRefresher,
            workTypeStatusRepository: workTypeStatusRepository,
            editableWorksiteProvider: editableWorksiteProvider,
            appEnv: appEnv,
            loggerFactory: loggerFactory
        )
        uiState = dataLoader.uiState.eraseToAnyPublisher()

        organizationLookup = organizationsRepository.organizationLookup.eraseToAnyPublisher()

        editableWorksite = editableWorksiteProvider.editableWorksite.eraseToAnyPublisher()

        nextRecurDateFormat = DateFormatter()
        nextRecurDateFormat.dateFormat = "EEE MMMM d yyyy 'at' h:mm a"

        updateHeaderTitle()
        subscribeSubTitle()
    }

    deinit {
        dataLoader.unsubscribe()
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .sequentiallyConsistent)

        if isFirstAppear {
            editableWorksiteProvider.reset(incidentIdIn)

            Task {
                await accountDataRefresher.updateMyOrganization(false)
            }
        }
        transferWorkTypeProvider.clearPendingTransfer()

        subscribeLoading()
        subscribeSyncing()
        subscribeSaving()
        subscribePendingTransfer()
        subscribeEditableState()
        subscribeViewState()

        subscribeCaseData()
        subscribeWorksiteChange()
        subscribeWorkTypeProfile()
        subscribeFilesNotes()
        subscribeLocalImages()

        if isFirstAppear {
            dataLoader.loadData(
                incidentIdIn: incidentIdIn,
                worksiteIdIn: worksiteIdIn,
                translate: localTranslate
            )
        }

        if let note = editableWorksiteProvider.takeNote() {
            saveNote(note)
        }
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeLoading() {
        dataLoader.isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeSyncing() {
        Publishers.CombineLatest(
            worksiteChangeRepository.syncingWorksiteIds.eraseToAnyPublisher(),
            localImageRepository.syncingWorksiteId.eraseToAnyPublisher()
        )
            .eraseToAnyPublisher()
            .map { worksiteIds, imageWorksiteId in
                let worksiteId = self.worksiteIdIn
                return worksiteIds.contains(worksiteId) ||
                imageWorksiteId == worksiteId
            }
            .receive(on: RunLoop.main)
            .assign(to: \.isSyncing, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeSaving() {
        Publishers.CombineLatest(
            isSavingWorksite.eraseToAnyPublisher(),
            isSavingMedia.eraseToAnyPublisher()
        )
        .map { (b0, b1) in b0 || b1 }
        .receive(on: RunLoop.main)
        .assign(to: \.isSaving, on: self)
        .store(in: &subscriptions)
    }

    private func subscribePendingTransfer() {
        transferWorkTypeProvider.isPendingTransferPublisher
            .assign(to: \.isPendingTransfer, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeEditableState() {
        Publishers.CombineLatest3(
            $isPendingTransfer.eraseToAnyPublisher(),
            $isLoading.eraseToAnyPublisher(),
            $isSaving.eraseToAnyPublisher()
        )
        .map { (b0, b1, b2) in b0 || b1 || b2 }
        .sink { isTransient in
            self.editableViewState.isEditable = !isTransient
        }
        .store(in: &subscriptions)
    }

    private func subscribeViewState() {
        $alertMessage
            .filter { $0.isNotBlank }
            .debounce(
                for: .seconds(2),
                scheduler: RunLoop.current
            )
            .receive(on: RunLoop.main)
            .sink { _ in
                self.clearAlert()
            }
            .store(in: &subscriptions)
    }

    private func subscribeCaseData() {
        editableWorksiteProvider.editableWorksite
            .map { worksite in
                if let updatedAt = worksite.updatedAt {
                    return self.t("caseView.updated_ago")
                        .replacingOccurrences(of: "{relative_time}", with: updatedAt.relativeTime)
                }
                return ""
            }
            .receive(on: RunLoop.main)
            .assign(to: \.updatedAtText, on: self)
            .store(in: &subscriptions)

        uiState
            .throttle(
                for: .seconds(0.1),
                scheduler: RunLoop.current,
                latest: true
            )
            .map { state in
                let result: CaseEditorCaseData? = {
                    switch state {
                    case .caseData(let caseData): return caseData
                    default: return nil
                    }
                }()
                return result
            }
            .receive(on: RunLoop.main)
            .sink(receiveValue: { stateData in
                self.caseData = stateData
                self.statusOptions = stateData == nil ? [] : stateData!.statusOptions
            })
            .store(in: &subscriptions)
    }

    private func subscribeWorksiteChange() {
        dataLoader.worksiteStream
            .sink(receiveValue: { localWorksiteOptional in
                if let localWorksite = localWorksiteOptional {
                    self.worksitesRepository.setRecentWorksite(
                        incidentId: self.incidentIdIn,
                        worksiteId: localWorksite.worksite.id,
                        viewStart: Date()
                    )
                }
            })
            .store(in: &subscriptions)

        dataLoader.worksiteStream
            .receive(on: RunLoop.main)
            .sink(receiveValue: { localWorksiteOptional in
                if let localWorksite = localWorksiteOptional {
                    self.updateHeaderTitle(localWorksite.worksite.caseNumber)
                }
            })
            .store(in: &subscriptions)
    }

    private func subscribeWorkTypeProfile() {
        Publishers.CombineLatest3(
            $caseData.assertNoFailure().eraseToAnyPublisher(),
            editableWorksite,
            organizationLookup
        )
        .filter { (stateData, worksite, orgLookup) in
            stateData != nil &&
            !worksite.isNew &&
            orgLookup.isNotEmpty
        }
        .filter { (stateData, _, orgLookup) in
            orgLookup.keys.contains(stateData!.orgId)
        }
        .map { (stateData, worksite, orgLookup) in
            let stateData = stateData!
            let isTurnOnRelease = stateData.incident.turnOnRelease
            let myOrgId = stateData.orgId
            let worksiteWorkTypes = worksite.workTypes

            let myOrg = orgLookup[myOrgId]!

            let requestedTypes = Set(
                stateData.worksite.workTypeRequests
                    .filter { $0.hasNoResponse }
                    .map { $0.workType }
            )

            let summaries = self.getWorkTypeSummaries(
                worksiteWorkTypes,
                stateData,
                worksite,
                requestedTypes,
                isTurnOnRelease,
                myOrgId,
                myOrg
            )

            let claimedWorkType = summaries.filter { summary in summary.workType.orgClaim != nil }
            let unclaimed = summaries
                .filter { summary in summary.workType.orgClaim == nil }
                .sorted { a, b in
                    a.workType.workTypeLiteral.localizedCompare(b.workType.workTypeLiteral) == .orderedAscending
                }
            let otherOrgClaimedWorkTypes = claimedWorkType
                .filter { !$0.isClaimedByMyOrg }
            let orgClaimedWorkTypes = claimedWorkType
                .filter { $0.isClaimedByMyOrg }
                .sorted { a, b in
                    a.workType.workTypeLiteral.localizedCompare(b.workType.workTypeLiteral) == .orderedAscending
                }

            var otherOrgClaimMap = [Int64: [WorkTypeSummary]]()
            otherOrgClaimedWorkTypes.forEach { summary in
                let orgId = summary.workType.orgClaim!
                var otherOrgWorkTypes = otherOrgClaimMap[orgId] ?? []
                otherOrgWorkTypes.append(summary)
                otherOrgClaimMap[orgId] = otherOrgWorkTypes
            }
            let otherOrgClaims = otherOrgClaimMap.map { (orgId, summaries) in
                let name = orgLookup[orgId]?.name
                if name == nil {
                    self.refreshOrganizationLookup()
                }
                return OrgClaimWorkType(
                    orgId: orgId,
                    orgName: name ?? "",
                    workTypes: summaries
                        .sorted { a, b in
                            a.workType.workTypeLiteral.localizedCompare(b.workType.workTypeLiteral) == .orderedAscending
                        },
                    isMyOrg: false
                )
            }

            let myOrgName = myOrg.name
            let orgClaimed = OrgClaimWorkType(
                orgId: myOrgId,
                orgName: myOrgName,
                workTypes: orgClaimedWorkTypes,
                isMyOrg: true
            )

            let releasable = otherOrgClaimedWorkTypes
                .filter { summary in summary.isReleasable }
            // TODO: Does this sort perform as expected
                .sorted(by: { a, b in a.name.localizedStandardCompare(b.name) == .orderedAscending })
            let requestable = otherOrgClaimedWorkTypes
                .filter { summary in !(summary.isReleasable || summary.isRequested) }
            // TODO: Does this sort perform as expected
                .sorted(by: { a, b in a.name.localizedStandardCompare(b.name) == .orderedAscending })
            return WorkTypeProfile(
                orgId: myOrgId,
                otherOrgClaims: otherOrgClaims,
                orgClaims: orgClaimed,
                unclaimed: unclaimed,
                releasable: releasable,
                requestable: requestable,

                orgName: myOrgName,
                caseNumber: worksite.caseNumber
            )
        }
        .receive(on: RunLoop.main)
        .assign(to: \.workTypeProfile, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeFilesNotes() {
        let filesNotes = Publishers.CombineLatest(
            editableWorksite,
            $caseData.eraseToAnyPublisher()
        )
            .filter { (_, state) in state != nil }
            .map { (worksite, state) in
                let state = state!
                let fileImages = worksite.files.map { $0.asCaseImage() }
                let localImages: [CaseImage]
                if let localWorksiteImages = state.localWorksite {
                    localImages = localWorksiteImages.localImages.map { $0.asCaseImage() }
                } else {
                    localImages = []
                }
                return (fileImages, localImages, worksite.notes)
            }
            .share()

        filesNotes.map { (fileImages, localImages, notes) in
            let fileCount = fileImages.count + localImages.count
            var photosTitle = self.localTranslate("caseForm.photos")
            if fileCount > 0 {
                photosTitle = "\(photosTitle) (\(fileCount))"
            }

            var notesTitle = self.localTranslate("formLabels.notes")
            let noteCount = notes.count
            if noteCount > 0 {
                notesTitle = "\(notesTitle) (\(noteCount))"
            }

            return [
                .info: self.localTranslate("nav.info"),
                .photos: photosTitle,
                .notes: notesTitle
            ]
        }
        .receive(on: RunLoop.main)
        .assign(to: \.tabTitles, on: self)
        .store(in: &subscriptions)

        filesNotes.map { (files, localFiles, _) in
            let beforeImages = Array([
                localFiles.filter { !$0.isAfter },
                files.filter { !$0.isAfter }
            ].joined())
            let afterImages = Array([
                localFiles.filter { $0.isAfter },
                files.filter { $0.isAfter }
            ].joined())
            return [
                ImageCategory.before: beforeImages,
                ImageCategory.after: afterImages
            ]
        }
        .receive(on: RunLoop.main)
        .assign(to: \.beforeAfterPhotos, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeLocalImages() {
        localImageRepository.syncingWorksiteImage
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.syncingWorksiteImage, on: self)
            .store(in: &subscriptions)

        $beforeAfterPhotos
            .sink(receiveValue: {
                for (_, images) in $0 {
                    images.filter { !$0.isNetworkImage }
                        .forEach { localImage in
                            let imageName = localImage.imageName
                            if let cachedImage = self.localImageRepository.getLocalImage(imageName) {
                                self.localImageCache[localImage.imageUri] = cachedImage
                            }
                        }
                }
            })
            .store(in: &subscriptions)
    }

    private func getWorkTypeSummaries(
        _ worksiteWorkTypes: [WorkType],
        _ stateData: CaseEditorCaseData,
        _ worksite: Worksite,
        _ requestedTypes: Set<String>,
        _ isTurnOnRelease: Bool,
        _ myOrgId: Int64,
        _ myOrg: IncidentOrganization
    ) -> [WorkTypeSummary] {
        worksiteWorkTypes.map { workType in
            let workTypeLiteral = workType.workTypeLiteral
            var name = localTranslate(workTypeLiteral)
            if name == workTypeLiteral {
                name = localTranslate("workType.\(workTypeLiteral)")
            }
            let summaryJobTypes = worksite.summarizeWorkTypeJobs(
                stateData.incident.workTypeLookup,
                workTypeLiteral,
                localTranslate,
                name
            )
            let rRuleSummary: String? = {
//                if let rRuleString = workType.recur {
//                    // TODO: Use RRule library and customize where lacking
//                     return RRule(rRuleString).toHumanReadableText(translator)
//                }
                return nil
            }()
            let nextRecurSummary: String? = {
                if let nextRecurAt = workType.nextRecurAt,
                   nextRecurAt > Date.now {
                    let nextDate = nextRecurDateFormat.string(from: nextRecurAt)
                    return "\(localTranslate("shareWorksite.next_recur")) \(nextDate)"
                }
                return nil
            }()
            let summary = [
                summaryJobTypes.combineTrimText(),
                rRuleSummary,
                nextRecurSummary,
            ]
                .combineTrimText("\n")
            return WorkTypeSummary(
                workType: workType,
                name: name,
                jobSummary: summary,
                isRequested: requestedTypes.contains(workType.workTypeLiteral),
                isReleasable: isTurnOnRelease && workType.isReleaseEligible,
                myOrgId: myOrgId,
                isClaimedByMyOrg: myOrg.affiliateIds.contains(workType.orgClaim ?? -1)
            )
        }
    }

    private func refreshOrganizationLookup() {
        if !isOrganizationsRefreshed.exchange(true, ordering: .sequentiallyConsistent) {
            Task {
                await incidentsRepository.pullIncidentOrganizations(incidentIdIn, true)
            }
        }
    }

    private func updateHeaderTitle(_ caseNumber: String = "") {
        headerTitle = caseNumber.isBlank
        ? localTranslate("nav.work_view_case")
        : "\(localTranslate("actions.view")) \(caseNumber)"
    }

    private func subscribeSubTitle() {
        editableWorksite
            .map { worksite in
                worksite.isNew ? "" : [worksite.county, worksite.state]
                    .filter { $0.isNotBlank }
                    .joined(separator: ", ")
            }
            .receive(on: RunLoop.main)
            .assign(to: \.subTitle, on: self)
            .store(in: &subscriptions)
    }

    private var organizationId: Int64? { caseData?.orgId }

    private func saveWorksiteChange(
        _ startingWorksite: Worksite,
        _ changedWorksite: Worksite,
        _ onSaveAction: @escaping () -> Void = {}
    ) {
        if startingWorksite.isNew ||
            startingWorksite == changedWorksite {
            return
        }

        if let orgId = organizationId {
            self.isSavingWorksite.value = true
            Task {
                do {
                    defer {
                        Task { @MainActor in self.isSavingWorksite.value = false }
                    }

                    _ = try await self.worksiteChangeRepository.saveWorksiteChange(
                        worksiteStart: startingWorksite,
                        worksiteChange: changedWorksite,
                        primaryWorkType: changedWorksite.keyWorkType!,
                        organizationId: orgId
                    )

                    syncPusher.appPushWorksite(worksiteIdIn)

                    onSaveAction()
                } catch {
                    onSaveFail(error)
                }
            }
        }
    }

    private func onSaveFail(_ error: Error, _ isMediaSave: Bool = false) {
        logger.logError(error)

        // TODO: Show dialog save failed. Try again. If still fails seek help.
    }

    func removeFlag(_ flag: WorksiteFlag) {
        let startingWorksite = referenceWorksite
        if let worksiteFlags = startingWorksite.flags {
            let flagsDeleted = worksiteFlags.filter { $0.id != flag.id }
            if flagsDeleted.count < worksiteFlags.count {
                let changedWorksite = startingWorksite.copy { $0.flags = flagsDeleted }
                saveWorksiteChange(startingWorksite, changedWorksite)
            }
        }
    }

    func toggleAlert(message: String) {
        alert = true
        alertMessage = message
    }

    func clearAlert() {
        alert = false
        alertMessage = ""
    }

    func toggleFavorite() {
        let startingWorksite = referenceWorksite
        let changedWorksite =
        startingWorksite.copy { $0.isAssignedToOrgMember = !startingWorksite.isLocalFavorite }
        saveWorksiteChange(startingWorksite, changedWorksite) {
            let messageTranslateKey = changedWorksite.isLocalFavorite
            ? "caseView.member_my_org"
            : "~~Not member of my organization"
            let message = self.t(messageTranslateKey)
            Task { @MainActor in
                self.toggleAlert(message: message)
            }
        }
    }

    func toggleHighPriority() {
        let startingWorksite = referenceWorksite
        let changedWorksite = startingWorksite.toggleHighPriorityFlag()
        saveWorksiteChange(startingWorksite, changedWorksite) {
            let messageTranslateKey = changedWorksite.hasHighPriorityFlag
            ? "caseView.high_priority"
            : "caseView.not_high_priority"
            let message = self.t(messageTranslateKey)
            Task { @MainActor in
                self.toggleAlert(message: message)
            }
        }
    }

    func updateWorkType(_ workType: WorkType, _ isStatusChange: Bool) {
        let startingWorksite = referenceWorksite
        var updatedWorkTypes = startingWorksite.workTypes
            .filter { $0.workType != workType.workType }

        var updatedWorkType = workType
        if isStatusChange && workType.orgClaim == nil {
            updatedWorkType = workType.copy { $0.orgClaim = organizationId }
        }
        updatedWorkTypes.append(updatedWorkType)

        let changedWorksite = startingWorksite.copy { $0.workTypes = updatedWorkTypes }
        saveWorksiteChange(startingWorksite, changedWorksite)
    }

    func requestWorkType(_ workType: WorkType) {
        if let profile = workTypeProfile {
            transferWorkTypeProvider.startTransfer(
                profile.orgId,
                WorkTypeTransferType.request,
                profile.requestable.associate { summary in
                    let isSelected = summary.workType.id == workType.id
                    return (summary.workType, isSelected)
                },
                organizationName: profile.orgName,
                caseNumber: profile.caseNumber
            )
        }
    }

    func releaseWorkType(_ workType: WorkType) {
        if let profile = workTypeProfile {
            transferWorkTypeProvider.startTransfer(
                profile.orgId,
                WorkTypeTransferType.release,
                profile.releasable.associate { summary in
                    let isSelected = summary.workType.id == workType.id
                    return (summary.workType, isSelected)
                }
            )
        }
    }

    func claimAll() {
        if let orgId = organizationId {
            let startingWorksite = referenceWorksite
            let updatedWorkTypes =
            startingWorksite.workTypes
                .map {
                    $0.isClaimed ? $0: $0.copy { $0.orgClaim = orgId }
                }
            let changedWorksite = startingWorksite.copy { $0.workTypes = updatedWorkTypes }
            saveWorksiteChange(startingWorksite, changedWorksite)
        }
    }

    func requestAll() {
        if let profile = workTypeProfile {
            transferWorkTypeProvider.startTransfer(
                profile.orgId,
                WorkTypeTransferType.request,
                profile.requestable.associate { summary in (summary.workType, true) },
                organizationName: profile.orgName,
                caseNumber: profile.caseNumber
            )
        }
    }

    func releaseAll() {
        if let profile = workTypeProfile {
            transferWorkTypeProvider.startTransfer(
                profile.orgId,
                WorkTypeTransferType.release,
                profile.releasable.associate { summary in (summary.workType, true) }
            )
        }
    }

    func saveNote(_ note: WorksiteNote) {
        if note.note.isBlank {
            return
        }

        let startingWorksite = referenceWorksite
        var notes = [note]
        notes += startingWorksite.notes
        let changedWorksite = startingWorksite.copy { $0.notes = notes }
        saveWorksiteChange(startingWorksite, changedWorksite)
    }

    func onPhotoTaken(_ result: UIImage) {
        let categoryLiteral = addImageCategory.literal
        let count = cachingLocalImageCount[categoryLiteral]
        cachingLocalImageCount[categoryLiteral] = count + 1

        Task {
            do {
                defer {
                    Task { @MainActor in
                        let cachingCount = cachingLocalImageCount[categoryLiteral]
                        cachingLocalImageCount[categoryLiteral] = cachingCount - 1
                    }
                }

                try await self.localImageRepository.cacheImage(
                    incidentIdIn,
                    worksiteIdIn,
                    categoryLiteral,
                    result
                )

                syncPusher.scheduleSyncMedia()
            } catch {
                logger.logError(error)
            }
        }
    }

    func onMediaSelected(_ results: [PhotosPickerItem]) {
        let categoryLiteral = addImageCategory.literal
        let count = cachingLocalImageCount[categoryLiteral]
        let selectCount = results.count
        cachingLocalImageCount[categoryLiteral] = count + selectCount

        Task {
            do {
                defer {
                    Task { @MainActor in
                        let cachingCount = cachingLocalImageCount[categoryLiteral]
                        cachingLocalImageCount[categoryLiteral] = cachingCount - selectCount
                    }
                }

                try await self.localImageRepository.cachePicked(
                    incidentIdIn,
                    worksiteIdIn,
                    categoryLiteral,
                    results
                )

                syncPusher.scheduleSyncMedia()
            } catch {
                logger.logError(error)
            }
        }
    }

    func scheduleSync() {
        if !isSyncing {
            syncPusher.appPushWorksite(worksiteIdIn)
            syncPusher.scheduleSyncMedia()
        }
    }

    // MARK: KeyTranslator

    let translationCount: any Publisher<Int, Never>

    func translate(_ phraseKey: String) -> String? {
        localTranslate(phraseKey)
    }

    func t(_ phraseKey: String) -> String {
        localTranslate(phraseKey)
    }
}

struct WorkTypeSummary: Identifiable {
    let workType: WorkType
    let name: String
    let jobSummary: String
    let isRequested: Bool
    let isReleasable: Bool
    let myOrgId: Int64
    let isClaimedByMyOrg: Bool

    var id: String { workType.workTypeLiteral }
}

struct OrgClaimWorkType: Identifiable {
    let orgId: Int64
    let orgName: String
    let workTypes: [WorkTypeSummary]
    let isMyOrg: Bool

    var id: Int64 { orgId }
}

struct WorkTypeProfile {
    let orgId: Int64
    let otherOrgClaims: [OrgClaimWorkType]
    let orgClaims: OrgClaimWorkType
    let unclaimed: [WorkTypeSummary]
    let releasable: [WorkTypeSummary]
    let requestable: [WorkTypeSummary]
    let releasableCount: Int
    let requestableCount: Int

    let orgName: String
    let caseNumber: String

    init(
        orgId: Int64,
        otherOrgClaims: [OrgClaimWorkType],
        orgClaims: OrgClaimWorkType,
        unclaimed: [WorkTypeSummary],
        releasable: [WorkTypeSummary],
        requestable: [WorkTypeSummary],
        orgName: String,
        caseNumber: String
    ) {
        self.orgId = orgId
        self.otherOrgClaims = otherOrgClaims
        self.orgClaims = orgClaims
        self.unclaimed = unclaimed
        self.releasable = releasable
        self.requestable = requestable
        releasableCount = releasable.count
        requestableCount = requestable.count
        self.orgName = orgName
        self.caseNumber = caseNumber
    }
}

fileprivate extension Worksite {
    func summarizeWorkTypeJobs(
        _ workTypeLookup: [String: String],
        _ workTypeLiteral: String,
        _ translate: (String) -> String,
        _ name: String
    ) -> [String?] {
        if let formData = formData {
            return formData
                .filter { formValue in workTypeLookup[formValue.key] == workTypeLiteral }
                .filter { formValue in formValue.value.isBooleanTrue }
                .map { formValue in translate(formValue.key) }
                .filter { jobName in jobName != name }
                .filter { $0.isNotBlank == true }
        }
        return []
    }
}

enum ViewCaseTabs {
    case info
    case photos
    case notes
}
