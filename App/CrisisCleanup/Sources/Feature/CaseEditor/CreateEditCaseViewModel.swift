import Atomics
import Combine
import CoreLocation
import Foundation
import SwiftUI

let wrongLocationLabelKey = "caseForm.address_problems"
let highPriorityLabelKey = "flag.flag_high_priority"
let orgMemberLabelKey = "actions.member_of_my_org"

class CreateEditCaseViewModel: ObservableObject, KeyAssetTranslator {
    static func isOverClaiming(
        _ orgId: Int64,
        startingWorksite: Worksite,
        updatedWorksite: Worksite,
        repository: IncidentClaimThresholdRepository,
    ) async -> Bool {
        let endClaimCount = updatedWorksite.getClaimedCount(orgId)
        let startClaimCount = startingWorksite.getClaimedCount(orgId)
        let deltaClaimCount = endClaimCount - startClaimCount
        return await !repository.isWithinClaimCloseThreshold(updatedWorksite.id, deltaClaimCount)
    }

    private let accountDataRepository: AccountDataRepository
    private let incidentsRepository: IncidentsRepository
    private let worksitesRepository: WorksitesRepository
    private let appPreferences: AppPreferencesDataSource
    private var worksiteProvider: EditableWorksiteProvider
    private let incidentBoundsProvider: IncidentBoundsProvider
    private let locationManager: LocationManager
    private let locationSearchManager: LocationSearchManager
    private let networkMonitor: NetworkMonitor
    private let residentNameSearchManager: ResidentNameSearchManager
    private let existingWorksiteSelector: ExistingWorksiteSelector
    private let translator: KeyAssetTranslator
    private let incidentSelector: IncidentSelector
    private let claimThresholdRepository: IncidentClaimThresholdRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    let inputValidator: InputValidator
    private let syncPusher: SyncPusher
    private let worksiteImageRepository: WorksiteImageRepository
    private let logger: AppLogger

    private let dataLoader: CaseEditorDataLoader

    let incidentIdIn: Int64
    private let worksiteIdIn: Int64?
    var worksiteIdLatest: Int64?
    var isCreateWorksite: Bool { worksiteIdLatest == nil }

    private var hasNewWorksitePhotosImages: Bool {
        worksiteIdIn == nil &&
        worksiteImageRepository.hasNewWorksiteImages
    }

    private let localTranslate: (String) -> String

    @Published private(set) var headerTitle = ""

    let visibleNoteCount = 3

    @Published private(set) var isOnline = true

    @Published private(set) var isLoading = true

    @Published private(set) var isSyncing = false

    @Published var isMapSatelliteView = false

    @Published private(set) var areEditorsReady = false

    let editableViewState = EditableView()

    let caseMediaManager: CaseMediaManager

    private let editingWorksite: AnyPublisher<Worksite, Never>
    private var workTypeLookup = [String: WorkType]()

    private let viewState: AnyPublisher<CaseEditorViewState, Never>
    @Published private(set) var caseData: CaseEditorCaseData? = nil

    // For preventing unwanted editor reloads
    private var editorSetTime: Date?
    private let editorSetWindow: Double

    @Published private(set) var editSections: [String] = []
    @Published var statusOptions: [WorkTypeStatus] = []
    @Published private(set) var detailsFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var workFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var hazardsFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var volunteerFormFieldNode: FormFieldNode = EmptyFormFieldNode
    @Published private(set) var groupFormFieldNodes: [FormFieldNode] = []

    @Published private(set) var flagTranslateKeys: [String] = []

    let propertyInputData = PropertyInputData()
    let locationInputData = LocationInputData()
    @Published var isHighPriority = false
    @Published var isAssignedToOrgMember = false
    @Published private(set) var worksiteNotes = [WorksiteNote]()
    private var formFieldsInputData = FormFieldsInputData()
    @Published var binaryFormData = BindingBoolDictionary()
    @Published var contentFormData = BindingStringDictionary()
    @Published var workTypeStatusFormData = BindingStringDictionary()

    @Published var editingNote = ""
    @Published private(set) var otherNotes: [(String, String)] = []

    var hasInitialCoordinates: Bool { locationInputData.coordinates == caseData?.worksite.coordinates }
    @Published var showExplainLocationPermission = false
    private var useMyLocationExpirationTime = Date.epochZero
    @Published var locationOutOfBoundsMessage = ""

    private let invalidWorksiteInfoSubject = CurrentValueSubject<InvalidWorksiteInfo, Never>(InvalidWorksiteInfo())
    @Published private(set) var invalidWorksiteInfo = InvalidWorksiteInfo()

    private let navigateBackSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var navigateBack = false

    private let saveGuard = NSLock()
    private let isSavingWorksite = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSaving = false

    private let isChangingIncidentSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var changeWorksiteIncidentId = EmptyIncident.id
    private let changeExistingWorksiteSubject = CurrentValueSubject<ExistingWorksiteIdentifier, Never>(ExistingWorksiteIdentifierNone)
    @Published private(set) var changeExistingWorksite = ExistingWorksiteIdentifierNone
    private var saveChangeIncident = EmptyIncident
    private var changingIncidentWorksite = EmptyWorksite

    @Published private(set) var nameSearchResults = ResidentNameSearchResults()
    @Published private(set) var hasNameResults = false
    private let isSelectingWorksiteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSelectingWorksite = false
    private let editIncidentWorksiteSubject = CurrentValueSubject<ExistingWorksiteIdentifier, Never>(ExistingWorksiteIdentifierNone)
    @Published private(set) var editIncidentWorksite = ExistingWorksiteIdentifierNone

    @Published private(set) var incidentCreation = incidentCreationNow

    @Published var isOverClaimingWork = false

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions = Set<AnyCancellable>()

    init(
        accountDataRepository: AccountDataRepository,
        incidentsRepository: IncidentsRepository,
        incidentRefresher: IncidentRefresher,
        incidentBoundsProvider: IncidentBoundsProvider,
        worksitesRepository: WorksitesRepository,
        appPreferences: AppPreferencesDataSource,
        languageRepository: LanguageTranslationsRepository,
        languageRefresher: LanguageRefresher,
        workTypeStatusRepository: WorkTypeStatusRepository,
        accountDataRefresher: AccountDataRefresher,
        worksiteProvider: EditableWorksiteProvider,
        locationManager: LocationManager,
        addressSearchRepository: AddressSearchRepository,
        caseIconProvider: MapCaseIconProvider,
        networkMonitor: NetworkMonitor,
        searchWorksitesRepository: SearchWorksitesRepository,
        mapCaseIconProvider: MapCaseIconProvider,
        existingWorksiteSelector: ExistingWorksiteSelector,
        incidentSelector: IncidentSelector,
        claimThresholdRepository: IncidentClaimThresholdRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        syncPusher: SyncPusher,
        localImageRepository: LocalImageRepository,
        worksiteImageRepository: WorksiteImageRepository,
        inputValidator: InputValidator,
        translator: KeyAssetTranslator,
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory,
        incidentId: Int64,
        worksiteId: Int64?
    ) {
        self.accountDataRepository = accountDataRepository
        self.incidentsRepository = incidentsRepository
        self.worksitesRepository = worksitesRepository
        self.appPreferences = appPreferences
        self.worksiteProvider = worksiteProvider
        self.existingWorksiteSelector = existingWorksiteSelector
        self.incidentBoundsProvider = incidentBoundsProvider
        self.locationManager = locationManager
        self.networkMonitor = networkMonitor
        self.incidentSelector = incidentSelector
        self.claimThresholdRepository = claimThresholdRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.syncPusher = syncPusher
        self.worksiteImageRepository = worksiteImageRepository
        self.inputValidator = inputValidator

        self.translator = translator
        logger = loggerFactory.getLogger("create-edit-case")

        translationCount = translator.translationCount

        incidentIdIn = incidentId
        worksiteIdIn = worksiteId
        worksiteIdLatest = worksiteId

        caseMediaManager = CaseMediaManager(
            localImageRepository: localImageRepository,
            worksiteImageRepository: worksiteImageRepository,
            worksiteChangeRepository: worksiteChangeRepository,
            syncPusher: syncPusher,
            logger: logger,
            incidentId: incidentIdIn,
            worksiteId: worksiteIdLatest ?? EmptyWorksite.id
        )

        localTranslate = { phraseKey in
            worksiteProvider.translate(key: phraseKey) ?? translator.t(phraseKey)
        }

        residentNameSearchManager = ResidentNameSearchManager(
            incidentId: incidentIdIn,
            nameQuery: propertyInputData.$residentName,
            searchWorksitesRepository: searchWorksitesRepository,
            iconProvider: mapCaseIconProvider
        )

        let isNewWorksite = worksiteId==nil
        dataLoader = CaseEditorDataLoader(
            isCreateWorksite: isNewWorksite,
            incidentIdIn: incidentId,
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
            editableWorksiteProvider: worksiteProvider,
            appEnv: appEnv,
            loggerFactory: loggerFactory
        )
        viewState = dataLoader.viewState.eraseToAnyPublisher()

        editingWorksite = worksiteProvider.editableWorksite.eraseToAnyPublisher()

        addressSearchRepository.startSearchSession()
        // TODO: Subscribe to location search loading state?
        locationSearchManager = LocationSearchManager(
            incidentId: incidentId,
            locationQuery: PassthroughSubject<String, Never>()
                .eraseToAnyPublisher(),
            worksiteProvider: worksiteProvider,
            searchWorksitesRepository: searchWorksitesRepository,
            locationManager: locationManager,
            addressSearchRepository: addressSearchRepository,
            iconProvider: caseIconProvider,
            logger: logger
        )

        editorSetWindow = isNewWorksite ? 0.05.seconds : 0.6.seconds

        if isNewWorksite {
            worksiteImageRepository.clearNewWorksiteImages()
        }

        updateHeaderTitle()
    }

    deinit {
        dataLoader.unsubscribe()
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .sequentiallyConsistent)

        if isFirstAppear {
            let incidentChangeData = worksiteProvider.takeIncidentChanged()
            changingIncidentWorksite = incidentChangeData?.worksite ?? EmptyWorksite

            worksiteProvider.reset(incidentIdIn)
        }

        configureNameSearch()

        subscribeOnline()
        subscribeLoading()
        subscribeSyncing()
        subscribeSaving()
        subscribeMapState()
        subscribeEditableState()

        subscribeIncidentState()
        subscribeCaseData()
        subscribeWorksiteChange()
        subscribeLocationState()
        subscribeNameSearch()
        subscribePhotosImages()
        subscribeValidation()
        subscribeNavigation()
        subscribeIncidentChange()

        if isFirstAppear {
            dataLoader.loadData(
                incidentIdIn: incidentIdIn,
                worksiteIdIn: worksiteIdLatest,
                translate: localTranslate
            )
        } else if worksiteProvider.isAddressChanged {
            let worksite = worksiteProvider.editableWorksite.value
            locationInputData.load(worksite, true)
        } else if worksiteProvider.incidentIdChange != EmptyIncident.id {
            if let changeData = worksiteProvider.peekIncidentChange {
                let incidentChangeId = changeData.incident.id
                if incidentChangeId != EmptyIncident.id,
                   incidentChangeId != incidentIdIn {
                    // TODO: Change Case incident reliably without the delay hack?
                    isChangingIncidentSubject.value = true
                    Task {
                        do {
                            defer {
                                Task { @MainActor in
                                    onIncidentChange(
                                        locationInputData,
                                        changeData.incident,
                                        changeData.worksite
                                    )
                                    isChangingIncidentSubject.value = false
                                }
                            }
                            try await Task.sleep(for: .seconds(1.0))
                        }
                    }
                }
            }
        }
    }

    func onViewDisappear() {
        clearInvalidWorksiteInfo()
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeOnline() {
        networkMonitor.isOnline
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isOnline, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeLoading() {
        dataLoader.isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeSyncing() {
        if let worksiteId = self.worksiteIdLatest {
            worksiteChangeRepository.syncingWorksiteIds
                .eraseToAnyPublisher()
                .map { $0.contains(worksiteId) }
                .receive(on: RunLoop.main)
                .assign(to: \.isSyncing, on: self)
                .store(in: &subscriptions)
        }
    }

    private func subscribeSaving() {
        isSavingWorksite.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isSaving, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeMapState() {
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
    }

    private func subscribeEditableState() {
        let isTransientPublisher = Publishers.CombineLatest(
            $isSelectingWorksite,
            isChangingIncidentSubject
        )
            .map { (b0, b1) in b0 || b1 }
        Publishers.CombineLatest4(
            $areEditorsReady,
            $caseData,
            $isSaving,
            isTransientPublisher
        )
        .map { (editorsReady, cd, saving, transient) in
            return !editorsReady || cd?.isNetworkLoadFinished != true || saving || transient }
        .sink { isTransient in
            self.editableViewState.isEditable = !isTransient
        }
        .store(in: &subscriptions)
    }

    private func subscribeIncidentState() {
        viewState
            .compactMap { state in
                switch state {
                case .caseData(let caseData):
                    if let startAt = caseData.incident.startAt {
                        let daysDifference = startAt.distance(to: Date.now)
                        return IncidentCreation(isOldIncident: daysDifference > 180.days, relativeTime: startAt.relativeTime)
                    }
                default:
                    return nil
                }
                return nil
            }
            .receive(on: RunLoop.main)
            .assign(to: \.incidentCreation, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeCaseData() {
        viewState
            .compactMap { state in
                let result: CaseEditorCaseData? = {
                    switch state {
                    case .caseData(let caseData): return caseData
                    default: return nil
                    }
                }()
                return result
            }
            .filter { stateData in
                var passesFilter = false
                if stateData?.isNetworkLoadFinished == true {
                    if self.editorSetTime == nil ||
                        self.editorSetTime!.distance(to: Date.now) < self.editorSetWindow {
                        passesFilter = true
                    }
                    if passesFilter {
                        self.editorSetTime = Date.now
                    }
                }
                return passesFilter
            }
            .debounce(
                for: .seconds(editorSetWindow * 1.5),
                scheduler: RunLoop.current
            )
            .receive(on: RunLoop.main)
            .sink(receiveValue: { stateData in
                if self.changingIncidentWorksite != EmptyWorksite {
                    self.worksiteProvider.editableWorksite.value = self.changingIncidentWorksite
                }

                self.caseData = stateData
                self.statusOptions = stateData!.statusOptions
                self.setFormFieldNodes()

                var flagOptionTranslationKeys = [
                    wrongLocationLabelKey,
                    highPriorityLabelKey
                ]
                if self.isCreateWorksite {
                    flagOptionTranslationKeys.append(orgMemberLabelKey)
                }
                self.flagTranslateKeys = flagOptionTranslationKeys

                self.loadInitialWorksite()

                self.areEditorsReady = true
            })
            .store(in: &subscriptions)

        dataLoader.editSections
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.editSections, on: self)
            .store(in: &subscriptions)

        worksiteProvider.otherNotes
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.otherNotes, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeWorksiteChange() {
        dataLoader.worksiteStream
            .sink(receiveValue: { localWorksiteOptional in
                if let localWorksite = localWorksiteOptional {
                    let worksiteId = localWorksite.worksite.id
                    self.setRecentWorksite(
                        self.incidentIdIn,
                        worksiteId
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

    private func subscribeLocationState() {
        locationManager.$locationPermission
            .receive(on: RunLoop.main)
            .sink {
                if let status = $0,
                   self.locationManager.isAuthorized(status),
                   self.useMyLocationExpirationTime.distance(to: Date.now) < 0.seconds {
                    self.updateCoordinatesToMyLocation()
                }
            }
            .store(in: &subscriptions)

        locationInputData.$coordinates
            .map { $0.coordinates }
            .map {
                self.worksiteProvider.getOutOfBoundsMessage($0, self.translator.t)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.locationOutOfBoundsMessage, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeNameSearch() {
        residentNameSearchManager.searchResults
            .receive(on: RunLoop.main)
            .assign(to: \.nameSearchResults, on: self)
            .store(in: &subscriptions)

        $nameSearchResults
            .map { $0.isNotEmpty }
            .assign(to: \.hasNameResults, on: self)
            .store(in: &subscriptions)

        isSelectingWorksiteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isSelectingWorksite, on: self)
            .store(in: &subscriptions)

        editIncidentWorksiteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.editIncidentWorksite, on: self)
            .store(in: &subscriptions)
    }

    private func subscribePhotosImages() {
        let categorizedImages = if isCreateWorksite {
            worksiteImageRepository.streamNewWorksiteImages()
                .eraseToAnyPublisher()
                .mapToCategoryLookup()
        } else {
            processWorksiteFilesNotes(
                editableWorksite: worksiteProvider.editableWorksite,
                viewState: viewState
            )
            .organizeBeforeAfterPhotos()
        }
        caseMediaManager.subscribeCategorizedImages(categorizedImages, &subscriptions)

        caseMediaManager.subscribeLocalImages(&subscriptions)
    }

    private func subscribeValidation() {
        invalidWorksiteInfoSubject
            .receive(on: RunLoop.main)
            .assign(to: \.invalidWorksiteInfo, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeNavigation() {
        navigateBackSubject
            .receive(on: RunLoop.main)
            .assign(to: \.navigateBack, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeIncidentChange() {
        changeExistingWorksiteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.changeExistingWorksite, on: self)
            .store(in: &subscriptions)
    }

    private func updateHeaderTitle(_ caseNumber: String = "") {
        headerTitle = {
            if caseNumber.isBlank {
                return isCreateWorksite
                ? localTranslate("casesVue.new_case")
                : localTranslate("nav.work_view_case")
            } else {
                return "\(localTranslate("actions.view")) \(caseNumber)"
            }
        }()
    }

    private func setRecentWorksite(
        _ incidentId: Int64,
        _ worksiteId: Int64
    ) {
        if incidentId > 0 && worksiteId > 0 {
            self.worksitesRepository.setRecentWorksite(
                incidentId: incidentId,
                worksiteId: worksiteId,
                viewStart: Date()
            )
        }
    }

    private func setFormFieldNodes() {
        detailsFormFieldNode = worksiteProvider.getGroupNode(DetailsFormGroupKey)
        workFormFieldNode = worksiteProvider.getGroupNode(WorkFormGroupKey)
        hazardsFormFieldNode = worksiteProvider.getGroupNode(HazardsFormGroupKey)
        volunteerFormFieldNode = worksiteProvider.getGroupNode(VolunteerReportFormGroupKey)
        groupFormFieldNodes = [
            detailsFormFieldNode,
            workFormFieldNode,
            hazardsFormFieldNode,
            volunteerFormFieldNode
        ]
    }

    private func loadInitialWorksite() {
        let worksite = worksiteProvider.editableWorksite.value

        propertyInputData.load(worksite)
        locationInputData.load(worksite)
        isHighPriority = worksite.hasHighPriorityFlag
        isAssignedToOrgMember = worksite.isAssignedToOrgMember
        worksiteNotes.append(contentsOf: worksite.notes)

        if !isCreateWorksite {
            let formFieldsInputData = loadFormFieldsInputData(worksiteProvider)
            for binaryField in formFieldsInputData.binaryFields {
                binaryFormData[binaryField] = true
            }
            for (key, value) in formFieldsInputData.contentFields {
                contentFormData[key] = value
            }
            for (key, value) in formFieldsInputData.workTypeStatuses {
                workTypeStatusFormData[key] = value.literal
            }
            self.formFieldsInputData = formFieldsInputData
        }

        isHighPriority = worksite.hasHighPriorityFlag
        isAssignedToOrgMember = worksite.isAssignedToOrgMember
        locationInputData.hasWrongLocation = worksite.hasWrongLocationFlag

        workTypeLookup = worksite.workTypes.associateBy { $0.workTypeLiteral }

        configureNameSearch()
    }

    func scheduleSync() {
        if !isSyncing,
           let worksiteId = worksiteIdLatest {
            syncPusher.appPushWorksite(worksiteId, true)
        }
    }

    private func configureNameSearch() {
        let worksite = worksiteProvider.editableWorksite.value
        residentNameSearchManager.updateSteadyStateName(worksite.name)
        residentNameSearchManager.setIgnoreNetworkId(worksite.networkId)
    }

    func stopSearchingName() {
        residentNameSearchManager.stopSearchingWorksites()
    }

    func onExistingWorksiteSelected(_ result: CaseSummaryResult) {
        if isSelectingWorksite {
            return
        }

        isSelectingWorksiteSubject.value = true
        Task {
            do {
                defer { isSelectingWorksiteSubject.value = false }

                let existingWorksite = await existingWorksiteSelector.onNetworkWorksiteSelected(networkWorksiteId: result.networkWorksiteId)
                if existingWorksite != ExistingWorksiteIdentifierNone {
                    self.worksiteProvider.reset()
                    editIncidentWorksiteSubject.value = existingWorksite
                }
            }
        }
    }

    private func updateCoordinatesToMyLocation() {
        if let location = locationManager.getLocation() {
            let coordinates = location.coordinate
            let latLng = coordinates.latLng
            locationInputData.coordinates = latLng
            worksiteProvider.editableWorksite.value = worksiteProvider.copyCoordinates(coordinates)

            Task {
                if let address = await locationSearchManager.queryAddress(latLng) {
                    Task { @MainActor in
                        locationInputData.setSearchedLocationAddress(address)
                    }
                }
            }
        }
    }

    func useMyLocation() {
        if locationManager.requestLocationAccess() {
            updateCoordinatesToMyLocation()
        } else {
            useMyLocationExpirationTime = Date.now.addingTimeInterval(20.seconds)
        }

        if locationManager.isDeniedLocationAccess {
            showExplainLocationPermission = true
        }
    }

    func saveNote(_ note: WorksiteNote) {
        worksiteNotes.insert(note, at: 0)
    }

    func isWorkTypeClaimed(workType: String) -> Bool {
        workTypeLookup[workType]?.orgClaim != nil
    }

    private func clearInvalidWorksiteInfo() {
        invalidWorksiteInfoSubject.value = InvalidWorksiteInfo()
    }

    private func locationAddressInvalidInfo(
        _ translateKey: String,
        _ invalid: CaseEditorElement
    ) -> InvalidWorksiteInfo {
        let invalidElement = invalid == .location || locationInputData.isSearchSuggested ? .location : invalid
        return InvalidWorksiteInfo(invalidElement, t(translateKey))
    }

    private func validate(_ worksite: Worksite) -> InvalidWorksiteInfo {
        if worksite.name.isBlank {
            return InvalidWorksiteInfo(.name, t("caseForm.name_required"))
        }
        if worksite.phone1.isBlank {
            return InvalidWorksiteInfo(.phone, t("caseForm.phone_required"))
        }

        if worksite.latitude == 0.0 || worksite.longitude == 0.0 {
            return locationAddressInvalidInfo("caseForm.no_lat_lon_error", .location)
        }
        if worksite.address.isBlank {
            return locationAddressInvalidInfo("caseForm.address_required", .address)
        }
        if worksite.city.isBlank {
            return locationAddressInvalidInfo("caseForm.city_required", .city)
        }
        if worksite.county.isBlank {
            return locationAddressInvalidInfo("caseForm.county_required", .county)
        }
        if worksite.state.isBlank {
            return locationAddressInvalidInfo("caseForm.state_required", .state)
        }
        if worksite.postalCode.isBlank {
            return locationAddressInvalidInfo("caseForm.postal_code_required", .zipCode)
        }

        if worksite.workTypes.isEmpty ||
            worksite.keyWorkType == nil ||
            worksite.workTypes.first(where: { $0.workType == worksite.keyWorkType!.workType }) == nil
        {
            return InvalidWorksiteInfo(.work, t("caseForm.select_work_type_error"))
        }

        return InvalidWorksiteInfo()
    }

    private func onIncidentChange(
        _ inputData: LocationInputData,
        _ changeIncident: Incident,
        _ addressChangeWorksite: Worksite
    ) {
        inputData.assumeLocationAddressChanges(addressChangeWorksite)

        var copiedWorksite = copyChanges()
        if copiedWorksite != EmptyWorksite {
            if copiedWorksite.isNew {
                copiedWorksite = transferNotes(copiedWorksite, takeEditingNote: true)
                worksiteProvider.updateIncidentChangeWorksite(copiedWorksite)
                incidentSelector.selectIncident(changeIncident)
                changeWorksiteIncidentId = changeIncident.id
            } else {
                _ = worksiteProvider.takeIncidentChanged()

                saveChangeIncident = changeIncident
                saveChanges(false, backOnSuccess: false)
            }
        }
    }

    private func isOverClaiming(
        startingWorksite: Worksite,
        updatedWorksite: Worksite,
    ) async -> Bool {
        do {
            let accountDataPublisher = accountDataRepository.accountData.eraseToAnyPublisher()
            let accountData = try await accountDataPublisher.asyncFirst()
            let orgId = accountData.org.id
            return await CreateEditCaseViewModel.isOverClaiming(
                orgId,
                startingWorksite: startingWorksite,
                updatedWorksite: updatedWorksite,
                repository: claimThresholdRepository,
            )
        } catch {
            logger.logError(error)
        }
        return false
    }

    func saveChanges(
        _ claimUnclaimed: Bool,
        backOnSuccess: Bool = true
    ) {
        if !transferChanges(true) {
            return
        }

        saveGuard.withLock {
            if isSaving {
                return
            }
            isSavingWorksite.value = true
        }

        Task {
            do {
                defer {
                    saveGuard.withLock {
                        isSavingWorksite.value = false
                    }
                }

                guard let initialWorksite = caseData?.worksite else {
                    return
                }

                let worksite = worksiteProvider.editableWorksite.value
                    .updateKeyWorkType(initialWorksite)
                let saveIncidentId = saveChangeIncident.id
                let isIncidentChange = saveIncidentId != EmptyIncident.id &&
                saveIncidentId != worksite.incidentId
                if worksite == initialWorksite,
                   !isIncidentChange,
                   (!claimUnclaimed || worksite.unclaimedCount == 0) {
                    if hasNewWorksitePhotosImages {
                        invalidWorksiteInfoSubject.value = propertyInputData.getInvalidSection(inputValidator, t)
                        return
                    }

                    if backOnSuccess {
                        navigateBackSubject.value = true
                    }
                    return
                }

                let validation = validate(worksite)
                if validation.invalidElement != .none {
                    invalidWorksiteInfoSubject.value = validation
                    return
                }

                var keyWorkType = worksite.keyWorkType
                let orgId = caseData!.orgId
                var workTypes = worksite.workTypes
                if claimUnclaimed {
                    workTypes = workTypes.map {
                        $0.orgClaim != nil ? $0 : $0.copy { $0.orgClaim = orgId }
                    }
                    keyWorkType = workTypes.matchKeyWorkType(initialWorksite)
                }

                let updatedIncidentId = isIncidentChange ? saveIncidentId : worksite.incidentId
                let updatedReportedBy = worksite.isNew ? orgId : worksite.reportedBy
                let clearWhat3Words = worksite.what3Words?.isNotBlank == true &&
                        worksite.latitude != initialWorksite.latitude ||
                        worksite.longitude != initialWorksite.longitude
                let updatedWhat3Words = clearWhat3Words ? "" : worksite.what3Words

                let updatedWorksite = worksite.copy {
                    $0.incidentId = updatedIncidentId
                    $0.keyWorkType = keyWorkType
                    $0.workTypes = workTypes
                    $0.reportedBy = updatedReportedBy
                    $0.updatedAt = Date.now
                    $0.what3Words = updatedWhat3Words
                }

                if !isCreateWorksite,
                   await isOverClaiming(
                    startingWorksite: worksite,
                    updatedWorksite: updatedWorksite,
                   )
                {
                    Task { @MainActor in
                        self.isOverClaimingWork = true
                    }
                    return
                }

                try await Task.sleep(for: .seconds(0.1))
                worksiteIdLatest = try await worksiteChangeRepository.saveWorksiteChange(
                    worksiteStart: initialWorksite,
                    worksiteChange: updatedWorksite,
                    primaryWorkType: updatedWorksite.keyWorkType!,
                    organizationId: orgId
                )
                let worksiteId = worksiteIdLatest!

                if hasNewWorksitePhotosImages {
                    caseMediaManager.updateWorksiteId(worksiteId)
                    await worksiteImageRepository.transferNewWorksiteImages(worksiteId)
                }

                worksiteProvider.setEditedLocation(worksite.coordinates.coordinates)
                if isIncidentChange {
                    let _ = await incidentSelector.submitIncidentChange(saveChangeIncident)
                } else {
                    editorSetTime = nil
                    dataLoader.reloadData(worksiteId)
                }

                syncPusher.appPushWorksite(worksiteId, true)

                if isCreateWorksite {
                    claimThresholdRepository.onWorksiteCreated(worksiteId)
                }

                worksitesRepository.setRecentWorksite(
                    incidentId: updatedIncidentId,
                    worksiteId: worksiteId,
                    viewStart: Date.now,
                )

                if isIncidentChange {
                    changeExistingWorksiteSubject.value = ExistingWorksiteIdentifier(
                        incidentId: saveIncidentId,
                        worksiteId: worksiteId
                    )
                } else if backOnSuccess {
                    navigateBackSubject.value = true
                }
            } catch {
                logger.logError(error)

                // TODO: Show dialog save failed. Try again. If still fails seek help.
            }
        }
    }

    private func transferFlags(_ worksite: Worksite) -> Worksite {
        var worksite = worksite

        worksite = worksite.copyModifiedFlag(isHighPriority) {
            $0.isHighPriority || $0.isHighPriorityFlag
        } _: {
            WorksiteFlag.highPriority()
        }

        if isCreateWorksite {
            worksite = worksite.copy {
                $0.isAssignedToOrgMember = isAssignedToOrgMember
            }
        }

        return worksite
    }

    private func transferNotes(_ worksite: Worksite, takeEditingNote: Bool = false) -> Worksite {
        var worksite = worksite

        if takeEditingNote &&
            editingNote.isNotBlank && (
                worksiteNotes.isEmpty || worksiteNotes.first!.note.trim() != editingNote.trim()
            ) {
            let note = WorksiteNote.create().copy {
                $0.note = editingNote.trim()
            }
            worksiteNotes.insert(note, at: 0)
            editingNote = ""
        }

        if worksiteNotes.count > worksite.notes.count {
            worksite = worksite.copy {
                $0.notes = Array(worksiteNotes)
            }
        }

        return worksite
    }

    private func transferFormData(_ worksite: Worksite) -> Worksite {
        var worksite = worksite

        let offFieldKeys = Set(
            formFieldsInputData.groupFields
                .filter { $0.dynamicValue.isBool && binaryFormData[$0.key] != true }
                .flatMap { $0.childKeys }
        )

        let managedGroups = formFieldsInputData.managedGroups
        var formData = [String: WorksiteFormValue]()
        let contentData = contentFormData.data
        for (key, value) in contentData {
            if value.isNotBlank &&
                !offFieldKeys.contains(key) &&
                !managedGroups.contains(key) {
                formData[key] = WorksiteFormValue(valueString: value)
            }
        }
        for (key, value) in binaryFormData.data {
            if !contentData.keys.contains(key),
               value,
               !offFieldKeys.contains(key),
               !managedGroups.contains(key) {
                formData[key] = worksiteFormValueTrue
            }
        }
        worksite = worksite.copy {
            $0.formData = formData
        }

        return worksite
    }

    private func copyUnchangedData(initialWorksite: Worksite, worksite: Worksite) -> Worksite {
        var worksite = worksite

        if (initialWorksite.flags ?? []).isEmpty &&
            (worksite.flags ?? []).isEmpty {
            worksite = worksite.copy {
                $0.flags = initialWorksite.flags
            }
        }

        if (initialWorksite.formData ?? [:]).isEmpty &&
            (worksite.formData ?? [:]).isEmpty {
            worksite = worksite.copy {
                $0.formData = initialWorksite.formData
            }
        }

        return worksite
    }

    private func transferWorkTypesStatus(incident: Incident, worksite: Worksite) -> Worksite {
        var worksite = worksite

        var workTypeStatusLookup = [String: WorkTypeStatus]()
        for (key, value) in workTypeStatusFormData.data {
            workTypeStatusLookup[key] = statusFromLiteral(value, .openUnassigned)
        }
        worksite = worksite.updateWorkTypeStatuses(
            incident.workTypeLookup,
            incident.formFieldLookup,
            workTypeStatusLookup
        )

        return worksite
    }

    private func transferChanges(_ indicateInvalidSection: Bool = false) -> Bool {
        if let caseData = caseData {
            let initialWorksite = caseData.worksite
            var worksite: Worksite? = initialWorksite

            worksite = propertyInputData.updateCase(worksite!, inputValidator, t)
            if worksite == nil {
                if indicateInvalidSection {
                    invalidWorksiteInfoSubject.value = propertyInputData.getInvalidSection(inputValidator, t)
                }
                return false
            }

            worksite = locationInputData.updateCase(worksite!, t)
            if worksite == nil {
                if indicateInvalidSection {
                    invalidWorksiteInfoSubject.value = locationInputData.getInvalidSection(t)
                }
                return false
            }

            worksite = transferFlags(worksite!)

            worksite = transferNotes(worksite!, takeEditingNote: true)

            worksite = transferFormData(worksite!)

            worksite = copyUnchangedData(initialWorksite: initialWorksite, worksite: worksite!)

            worksite = transferWorkTypesStatus(incident: caseData.incident, worksite: worksite!)

            worksiteProvider.editableWorksite.value = worksite!
        }

        return true
    }

    private func copyChanges() -> Worksite {
        if let caseData = caseData {
            let initialWorksite = caseData.worksite
            var worksite: Worksite? = initialWorksite

            if let propertyWorksite = propertyInputData.updateCase(worksite!, inputValidator, t) {
                worksite = propertyWorksite
            }

            if let locationWorksite = locationInputData.updateCase(worksite!, t) {
                worksite = locationWorksite
            }

            worksite = transferFlags(worksite!)

            worksite = transferNotes(worksite!)

            worksite = transferFormData(worksite!)

            worksite = copyUnchangedData(initialWorksite: initialWorksite, worksite: worksite!)

            worksite = transferWorkTypesStatus(incident: caseData.incident, worksite: worksite!)

            return worksite!
        }

        return EmptyWorksite
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

enum CaseEditorElement {
    case none,
         name,
         phone,
         email,
         location,
         address,
         city,
         county,
         state,
         zipCode,
         work

    var scrollId: String {
        switch self {
        case .none: return ""
        case .name: return "property-name-error"
        case .phone: return "property-phone-error"
        case .email: return "property-email-error"
        case .location: return "location-section"
        case .address: return "location-address-error"
        case .city: return "location-city-error"
        case .county: return "location-county-error"
        case .state: return "location-state-error"
        case .zipCode: return "location-zip-code-error"
        case .work: return "section2"
        }
    }

    var focusElement: TextInputFocused {
        switch self {
        case .none: return .anyTextInput
        case .name: return .caseInfoName
        case .phone: return .caseInfoPhone
        case .email: return .caseInfoEmail
        case .location: return .anyTextInput
        case .address: return .caseInfoStreetAddress
        case .city: return .caseInfoCity
        case .county: return .caseInfoCounty
        case .state: return .caseInfoState
        case .zipCode: return .caseInfoZipCode
        case .work: return .anyTextInput
        }
    }
}

struct InvalidWorksiteInfo: Equatable {
    let invalidElement: CaseEditorElement
    let message: String
    let timestamp: Date

    init(
        _ invalidElement: CaseEditorElement = .none,
        _ message: String = ""
    ) {
        self.invalidElement = invalidElement
        self.message = message
        timestamp = Date.now
    }
}

struct IncidentCreation: Equatable {
    let isOldIncident: Bool
    let relativeTime: String
}

private let incidentCreationNow = IncidentCreation(isOldIncident: false, relativeTime: "")
