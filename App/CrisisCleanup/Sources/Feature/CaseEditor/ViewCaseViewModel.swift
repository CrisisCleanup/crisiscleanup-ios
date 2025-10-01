import Atomics
import Combine
import Foundation
import PhotosUI
import SwiftUI

class ViewCaseViewModel: ObservableObject, KeyAssetTranslator {
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let accountDataRefresher: AccountDataRefresher
    private let appPreferences: AppPreferencesDataSource
    private let worksiteInteractor: WorksiteInteractor
    private let locationManager: LocationManager
    private var editableWorksiteProvider: EditableWorksiteProvider
    private let transferWorkTypeProvider: TransferWorkTypeProvider
    private let localImageRepository: LocalImageRepository
    private let claimThresholdRepository: IncidentClaimThresholdRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let syncPusher: SyncPusher
    private let inputValidator: InputValidator
    private let translator: KeyAssetTranslator
    private let logger: AppLogger

    private let dataLoader: CaseEditorDataLoader

    let isValidWorksiteIds: Bool
    let incidentIdIn: Int64
    let worksiteIdIn: Int64

    private let localTranslate: (String) -> String

    @Published private(set) var headerTitle = ""
    @Published private(set) var subTitle = ""

    @Published private(set) var updatedAtText = ""

    @Published private(set) var phoneNumberValidations = [PhoneNumberValidation]()

    @Published private(set) var distanceAway = ""

    @Published var isMapSatelliteView = false

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

    let caseMediaManager: CaseMediaManager

    private let isOrganizationsRefreshed = ManagedAtomic(false)
    private let organizationLookup: AnyPublisher<[Int64: IncidentOrganization], Never>

    private let editableWorksite: AnyPublisher<Worksite, Never>

    private let viewState: AnyPublisher<CaseEditorViewState, Never>
    @Published private(set) var caseData: CaseEditorCaseData? = nil

    var referenceWorksite: Worksite { caseData?.worksite ?? EmptyWorksite }

    @Published private(set) var workTypeProfile: WorkTypeProfile? = nil

    @Published private(set) var tabTitles: [ViewCaseTab: String] = [
        .info: "",
        .photos: "",
        .notes: ""
    ]
    @Published private(set) var statusOptions: [WorkTypeStatus] = []

    @Published private(set) var otherNotes: [(String, String)] = []

    private let nextRecurDateFormat: DateFormatter

    @Published var isOverClaimingWork = false

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
        organizationsRepository: OrganizationsRepository,
        accountDataRefresher: AccountDataRefresher,
        appPreferences: AppPreferencesDataSource,
        organizationRefresher: OrganizationRefresher,
        worksiteInteractor: WorksiteInteractor,
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
        worksiteImageRepository: WorksiteImageRepository,
        claimThresholdRepository: IncidentClaimThresholdRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        syncPusher: SyncPusher,
        inputValidator: InputValidator,
        translator: KeyAssetTranslator,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory,
        incidentId: Int64,
        worksiteId: Int64
    ) {
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.accountDataRefresher = accountDataRefresher
        self.appPreferences = appPreferences
        self.worksiteInteractor = worksiteInteractor
        self.locationManager = locationManager
        self.editableWorksiteProvider = editableWorksiteProvider
        self.transferWorkTypeProvider = transferWorkTypeProvider
        self.localImageRepository = localImageRepository
        self.claimThresholdRepository = claimThresholdRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.inputValidator = inputValidator
        self.syncPusher = syncPusher
        self.translator = translator
        logger = loggerFactory.getLogger("view-case")

        translationCount = translator.translationCount

        incidentIdIn = incidentId
        worksiteIdIn = worksiteId
        isValidWorksiteIds = incidentId > 0 && worksiteId > 0

        caseMediaManager = CaseMediaManager(
            localImageRepository: localImageRepository,
            worksiteImageRepository: worksiteImageRepository,
            worksiteChangeRepository: worksiteChangeRepository,
            syncPusher: syncPusher,
            logger: logger,
            incidentId: incidentIdIn,
            worksiteId: worksiteIdIn
        )

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
            accountDataRefresher: accountDataRefresher,
            editableWorksiteProvider: editableWorksiteProvider,
            appEnv: appEnv,
            loggerFactory: loggerFactory
        )
        viewState = dataLoader.viewState.eraseToAnyPublisher()

        organizationLookup = organizationsRepository.organizationLookup.eraseToAnyPublisher()

        editableWorksite = editableWorksiteProvider.editableWorksite.eraseToAnyPublisher()

        nextRecurDateFormat = DateFormatter()
            .format("EEE MMMM d yyyy 'at' h:mm a")
            .utcTimeZone()

        updateHeaderTitle()

        organizationRefresher.pullOrganization(incidentIdIn)
    }

    deinit {
        dataLoader.unsubscribe()
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .sequentiallyConsistent)

        if isFirstAppear {
            worksiteInteractor.onSelectCase(incidentIdIn, worksiteIdIn)
            editableWorksiteProvider.reset(incidentIdIn)

            Task {
                await accountDataRefresher.updateMyOrganization(false)
            }
        }
        transferWorkTypeProvider.clearPendingTransfer()

        subscribeLoading()
        subscribeSyncing()
        subscribeSaving()
        subscribeSubTitle()
        subscribePendingTransfer()
        subscribeEditableState()
        subscribeViewState()

        subscribeCaseData()
        subscribeWorksiteChange()
        subscribeWorkTypeProfile()
        subscribeFilesNotes()
        subscribeLocalImages()
        subscribeLocationState()

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
        Task {
            do {
                let preferences = try await appPreferences.preferences.eraseToAnyPublisher().asyncFirst()
                let isMapSatelliteView = preferences.isMapSatelliteView ?? false
                Task { @MainActor in
                    self.isMapSatelliteView = isMapSatelliteView
                }
            } catch {
                logger.logError(error)
            }
        }

        $isMapSatelliteView
            .removeDuplicates()
            .sink {
                self.appPreferences.setMapSatelliteView($0)
            }
            .store(in: &subscriptions)

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

        viewState
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
                self.setDistanceAway()
            })
            .store(in: &subscriptions)

        $caseData
            .compactMap { $0?.worksite }
            .map {
                let phoneNumbers = [$0.phone1, $0.phone2].filterNotBlankTrim()
                let uniquePhoneNumbers = Set(phoneNumbers)
                return Array(uniquePhoneNumbers)
            }
            .map { (phoneNumbers: [String]) in
                let validated = phoneNumbers.map { phoneNumber in
                    self.inputValidator.validatePhoneNumber(phoneNumber)
                }
                return validated.sorted { a, b in
                    if a.isValid {
                        return true
                    }
                    if b.isValid {
                        return false
                    }
                    let deltaLength = a.formatted.count - b.formatted.count
                    if deltaLength == 0 {
                        return a.formatted < b.formatted
                    }
                    return deltaLength > 0
                }
            }
            .receive(on: RunLoop.main)
            .assign(to: \.phoneNumberValidations, on: self)
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
        editableWorksite.map { _ in
            self.editableWorksiteProvider.otherNotes.eraseToAnyPublisher()
        }
        .switchToLatest()
        .receive(on: RunLoop.main)
        .assign(to: \.otherNotes, on: self)
        .store(in: &subscriptions)

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
                return CaseImagesNotes(
                    networkImages: fileImages,
                    localImages: localImages,
                    notes: worksite.notes
                )
            }
            .share()

        Publishers.CombineLatest(
            filesNotes,
            $otherNotes
        )
        .map { (fn, on) in
            let fileCount = fn.networkImages.count + fn.localImages.count
            var photosTitle = self.localTranslate("caseForm.photos")
            if fileCount > 0 {
                photosTitle = "\(photosTitle) (\(fileCount))"
            }

            var notesTitle = self.localTranslate("formLabels.notes")
            let noteCount = fn.notes.count + on.count
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

        let categorizedImages = filesNotes
            .organizeBeforeAfterPhotos()
        caseMediaManager.subscribeCategorizedImages(categorizedImages, &subscriptions)
    }

    private func subscribeLocalImages() {
        caseMediaManager.subscribeLocalImages(&subscriptions)
    }

    private func subscribeLocationState() {
        locationManager.$location
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.setDistanceAway()
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
            let workTypeTranslateKey = "workType.\(workTypeLiteral)"
            var name = localTranslate(workTypeTranslateKey)
            if name == workTypeLiteral {
                name = localTranslate(workTypeLiteral)
            }
            let (summaryJobTypes, summaryJobDetails) = worksite.summarizeWorkTypeJobs(
                stateData.incident.workTypeLookup,
                workTypeLiteral,
                localTranslate,
                name
            )
            let rRuleSummary: String? = {
                if let rRuleString = workType.recur {
                    return Rrule.from(rRuleString).toHumanReadableText(translator)
                }
                return nil
            }()
            let nextRecurSummary: String? = {
                if let nextRecurAt = workType.nextRecurAt,
                   nextRecurAt > Date.now {
                    let nextDate = nextRecurDateFormat.string(from: nextRecurAt)
                    return localTranslate("shareWorksite.next_recur")
                        .replacingOccurrences(of: "{date}", with: nextDate)
                }
                return nil
            }()
            let summary = [
                summaryJobTypes.combineTrimText(),
                summaryJobDetails.combineTrimText("\n"),
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

    private func setDistanceAway() {
        var distanceAwayText = ""
        if let coordinates = locationManager.location?.coordinate,
           let worksite = caseData?.worksite {
            let worksiteLatRad = worksite.latitude.radians
            let worksiteLngRad = worksite.longitude.radians
            let latRad = coordinates.latitude.radians
            let lngRad = coordinates.longitude.radians
            let distanceAwayMi = haversineDistance(
                latRad, lngRad,
                worksiteLatRad, worksiteLngRad
            ).kmToMiles
            distanceAwayText = String(format: "%.01f", distanceAwayMi)
            distanceAwayText = "\(distanceAwayText) \(t("caseView.miles_abbrv"))"
        }
        distanceAway = distanceAwayText
    }

    func setEditedLocation() {
        if let coordinates = caseData?.worksite.coordinates {
            editableWorksiteProvider.setEditedLocation(coordinates.coordinates)
        }
    }

    private func isOverClaiming(
        startingWorksite: Worksite,
        updatedWorksite: Worksite,
    ) async -> Bool {
        if let orgId = organizationId {
            return await CreateEditCaseViewModel.isOverClaiming(
                orgId,
                startingWorksite: startingWorksite,
                updatedWorksite: updatedWorksite,
                repository: claimThresholdRepository,
            )
        }
        return false
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

                    if await isOverClaiming(
                        startingWorksite: startingWorksite,
                        updatedWorksite: changedWorksite,
                    ) {
                        Task { @MainActor in
                            self.isOverClaimingWork = true
                        }
                        return
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
            : "actions.not_member_of_my_org"
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

    private func saveWorkTypeChange(
        _ startingWorksite: Worksite,
        _ changedWorksite: Worksite
    ) {
        var updatedWorksite = changedWorksite

        var workTypes = changedWorksite.workTypes
        if workTypes.isNotEmpty {
            workTypes = workTypes.sorted { a, b in
                a.workTypeLiteral.localizedCompare(b.workTypeLiteral) == .orderedAscending
            }

            var keyWorkType = workTypes.first!
            if let keyWorkTypeLiteral = changedWorksite.keyWorkType?.workTypeLiteral,
               let matchingWorkType = workTypes.first(where: {
                    keyWorkTypeLiteral == $0.workTypeLiteral
               }) {
                keyWorkType = matchingWorkType
            }

            updatedWorksite = changedWorksite.copy {
                $0.keyWorkType = keyWorkType
            }
        }

        saveWorksiteChange(startingWorksite, updatedWorksite)
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
        saveWorkTypeChange(startingWorksite, changedWorksite)
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
            saveWorkTypeChange(startingWorksite, changedWorksite)
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

    func scheduleSync() {
        if !isSyncing {
            syncPusher.appPushWorksite(worksiteIdIn)
            syncPusher.scheduleSyncMedia()
        }
    }

    // MARK: KeyAssetTranslator

    let translationCount: any Publisher<Int, Never>

    func translate(_ phraseKey: String) -> String? {
        t(phraseKey)
    }

    func t(_ phraseKey: String) -> String {
        localTranslate(phraseKey)
    }

    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String {
        t(phraseKey)
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
    ) -> ([String?], [String?])  {
        if let formData = formData {
            let (jobTypes, jobDetails) = formData
                .filter { formValue in workTypeLookup[formValue.key] == workTypeLiteral }
                .split { formValue in formValue.value.isBooleanTrue }
            return (
                jobTypes
                    .map { formValue in translate("formLabels.\(formValue.key)") }
                    .filter { jobName in jobName != name }
                    .filter { $0.isNotBlank == true },
                jobDetails
                    .map { formValue in
                        let title = translate("formLabels.\(formValue.key)")
                        let description = translate(formValue.value.valueString)
                        return [title, description].combineTrimText(": ")
                    }
                    .filter { $0.isNotBlank == true }
            )
        }
        return ([], [])
    }
}

enum ViewCaseTab {
    case info
    case photos
    case notes
}
