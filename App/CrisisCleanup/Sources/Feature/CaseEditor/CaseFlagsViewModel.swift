import Atomics
import Combine
import Foundation
import SwiftUI

class CaseFlagsViewModel: ObservableObject {
    private let editableWorksiteProvider: EditableWorksiteProvider
    private let organizationsRepository: OrganizationsRepository
    private let incidentsRepository: IncidentsRepository
    private let databaseManagementRepository: DatabaseManagementRepository
    private let accountDataRepository: AccountDataRepository
    private let addressSearchRepository: AddressSearchRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let incidentSelectManager: IncidentSelector
    private let syncPusher: SyncPusher
    let translator: KeyAssetTranslator
    private let logger: AppLogger

    private let worksiteIn: Worksite
    private let flagsIn: Set<WorksiteFlagType>

    @Published private(set) var incidentWorksiteChange = (0, 0)
    private let incidentWorksiteChangeSubject = CurrentValueSubject<(Int64, Int64), Never>((0, 0))

    private let allFlags = [
        WorksiteFlagType.highPriority,
        WorksiteFlagType.upsetClient,
        WorksiteFlagType.markForDeletion,
        WorksiteFlagType.reportAbuse,
        WorksiteFlagType.duplicate,
        WorksiteFlagType.wrongLocation,
        WorksiteFlagType.wrongIncident,
    ]
    private let singleExistingFlags: Set<WorksiteFlagType> = [
        WorksiteFlagType.highPriority,
        WorksiteFlagType.upsetClient,
        WorksiteFlagType.markForDeletion,
        WorksiteFlagType.reportAbuse,
        WorksiteFlagType.duplicate,
    ]

    @Published private(set) var flagFlows: [WorksiteFlagType] = []

    @Published private(set) var isSaving = false
    private let isSavingSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSavingWorksite = false
    private let isSavingWorksiteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSaved = false
    private let isSavedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isEditable = false

    @Published private(set) var nearbyOrganizations: [IncidentOrganization]? = nil

    @Published var otherOrgQ = ""
    @Published var otherOrgResults = [OrganizationIdName]()

    private let wrongLocationManager: WrongLocationFlagManager
    @Published private(set) var isProcessingLocation = false
    @Published private(set) var wrongLocationText = ""
    @Published private(set) var validCoordinates: LocationAddress? = nil

    private let queryIncidentsManager: QueryIncidentsManager
    @Published private(set) var incidentQ = ""
    @Published private(set) var isLoadingIncidents = false
    @Published private(set) var incidentResults: (String, [IncidentIdNameType]) = ("", [])

    private let isFirstVisible = ManagedAtomic(true)

    private var subscriptions =  Set<AnyCancellable>()

    init(
        editableWorksiteProvider: EditableWorksiteProvider,
        organizationsRepository: OrganizationsRepository,
        incidentsRepository: IncidentsRepository,
        databaseManagementRepository: DatabaseManagementRepository,
        accountDataRepository: AccountDataRepository,
        addressSearchRepository: AddressSearchRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        incidentSelectManager: IncidentSelector,
        syncPusher: SyncPusher,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.editableWorksiteProvider = editableWorksiteProvider
        self.organizationsRepository = organizationsRepository
        self.incidentsRepository = incidentsRepository
        self.databaseManagementRepository = databaseManagementRepository
        self.accountDataRepository = accountDataRepository
        self.addressSearchRepository = addressSearchRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.incidentSelectManager = incidentSelectManager
        self.syncPusher = syncPusher
        self.translator = translator
        logger = loggerFactory.getLogger("add-case-flag")

        worksiteIn = editableWorksiteProvider.editableWorksite.value
        flagsIn = Set(worksiteIn.flags?.compactMap { $0.flagType } ?? [])

        wrongLocationManager = WrongLocationFlagManager(addressSearchRepository, logger)

        queryIncidentsManager = QueryIncidentsManager(incidentsRepository)

        let existingSingularFlags = Set(flagsIn.filter { singleExistingFlags.contains($0) })
        flagFlows = allFlags.filter { !existingSingularFlags.contains($0) }
    }

    func onViewAppear() {
        let isFirstAppear = isFirstVisible.exchange(false, ordering: .relaxed)
        if isFirstAppear {
            Task {
                await databaseManagementRepository.rebuildFts()
            }
        }

        subscribeToEditable()
        subscribeToWrongLocationManager()
        subscribeToQueryIncidentManager()
        subscribeToNearbyOrganizations()
        subscribeToOtherOrgResults()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeToEditable() {
        Publishers.CombineLatest3(
            isSavingSubject.eraseToAnyPublisher(),
            isSavingWorksiteSubject.eraseToAnyPublisher(),
            isSavedSubject.eraseToAnyPublisher()
        )
        .map { (b0, b1, b2) in !(b0 || b1 || b2) }
        .receive(on: RunLoop.main)
        .assign(to: \.isEditable, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeToWrongLocationManager() {
        wrongLocationManager.isProcessingLocation
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isProcessingLocation, on: self)
            .store(in: &subscriptions)

        wrongLocationManager.wrongLocationText
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.wrongLocationText, on: self)
            .store(in: &subscriptions)

        wrongLocationManager.validCoordinates
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.validCoordinates, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToQueryIncidentManager() {
        queryIncidentsManager.incidentQ.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentQ, on: self)
            .store(in: &subscriptions)

        queryIncidentsManager.isLoading.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingIncidents, on: self)
            .store(in: &subscriptions)

        queryIncidentsManager.incidentResults.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentResults, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToNearbyOrganizations() {
            editableWorksiteProvider.editableWorksite.asyncMap {
                let coordinates = $0.coordinates
                return await self.organizationsRepository.getNearbyClaimingOrganizations(
                    coordinates.latitude,
                    coordinates.longitude
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: \.nearbyOrganizations, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToOtherOrgResults() {
            $otherOrgQ
            .throttle(
                for: .seconds(0.15),
                      scheduler: RunLoop.current,
                      latest: true
            )
            .asyncMap {
                $0.isBlank || $0.trim().count < 2
                ? []
                : await self.organizationsRepository.getMatchingOrganizations($0.trim())
            }
            .receive(on: RunLoop.main)
            .assign(to: \.otherOrgResults, on: self)
            .store(in: &subscriptions)
    }

    private func commitFlag(
        _ flag: WorksiteFlag,
        overwrite: Bool = false,
        onPostSave: @escaping () -> Void
    ) {
        if let flagType = flag.flagType {
            if flagsIn.contains(flagType) && !overwrite {
                onPostSave()
                return
            }

            isSavingSubject.value = true
            Task {
                do {
                    defer { isSavingSubject.value = false }
                    try await saveFlag(flag, flagType)
                    onPostSave()
                } catch {
                    // TODO: Show error
                    logger.logError(error)
                }
            }
        }
    }

    private func commitFlag(
        _ flag: WorksiteFlag,
        _ overwrite: Bool = false
    ) {
        commitFlag(flag, overwrite: overwrite) {
            self.isSavedSubject.value = true
        }
    }

    private func saveWorksiteChange(
        _ startingWorksite: Worksite,
        _ changedWorksite: Worksite,
        _ schedulePush: Bool = false
    ) async throws {
        if (startingWorksite == changedWorksite) {
            return
        }

        isSavingWorksiteSubject.value = true
        do {
            defer { isSavingWorksiteSubject.value = false }

            let organizationId = try await accountDataRepository.accountData
                .eraseToAnyPublisher()
                .asyncFirst().org.id
            let primaryWorkType = startingWorksite.keyWorkType ?? startingWorksite.workTypes.first!
            _ = try await worksiteChangeRepository.saveWorksiteChange(
                worksiteStart: startingWorksite,
                worksiteChange: changedWorksite,
                primaryWorkType: primaryWorkType,
                organizationId: organizationId
            )

            if schedulePush {
                syncPusher.appPushWorksite(worksiteIn.id)
            }
        }
    }

    // TODO Test coverage. Especially overwriting
    private func saveFlag(
        _ flag: WorksiteFlag,
        _ flagType: WorksiteFlagType
    ) async throws {
        var currentFlags = worksiteIn.flags ?? []

        if flagsIn.contains(flagType) {
            let flagsDeleted = currentFlags.filter { $0.reasonT == flagType.literal }
            if flagsDeleted.count < currentFlags.count {
                try await saveWorksiteChange(
                    worksiteIn,
                    worksiteIn.copy { $0.flags = flagsDeleted }
                )
                currentFlags = flagsDeleted
            }
        }

        var flagAdded = Array(currentFlags)
        flagAdded.append(flag)

        try await saveWorksiteChange(
            worksiteIn,
            worksiteIn.copy { $0.flags = flagAdded },
            true
        )
    }

    func onHighPriority(_ isHighPriority: Bool, _ notes: String) {
        let highPriorityFlag = WorksiteFlag.flag(
            flag: WorksiteFlagType.highPriority,
            notes: notes,
            isHighPriorityBool: isHighPriority
        )
        commitFlag(highPriorityFlag)
    }

    func onOrgQueryChange(query: String) {
        otherOrgQ = query
    }

    func onUpsetClient(
        notes: String,
        isMyOrgInvolved: Bool?,
        otherOrgQuery: String,
        otherOrganizationsInvolved: [OrganizationIdName]
    ) {
        let isQueryMatchingOrg = otherOrganizationsInvolved.isNotEmpty &&
        otherOrgQuery.trim() == otherOrganizationsInvolved.first!.name.trim()

        let upsetClientFlag = WorksiteFlag.flag(
            flag: WorksiteFlagType.upsetClient,
            notes: notes
        )
        commitFlag(upsetClientFlag)
    }

    func onAddFlag(
        _ flagType: WorksiteFlagType,
        notes: String = "",
        overwrite: Bool = false
    ) {
        let worksiteFlag = WorksiteFlag.flag(
            flag: flagType,
            notes: notes
        )
        commitFlag(worksiteFlag, overwrite)
    }

    func onReportAbuse(
        isContacted: Bool?,
        contactOutcome: String,
        notes: String,
        action: String
    ) {
        let reportAbuseFlag = WorksiteFlag.flag(
            flag: WorksiteFlagType.reportAbuse,
            notes: notes,
            requestedAction: action
        )
        commitFlag(reportAbuseFlag)
    }

    func onWrongLocationTextChange(text: String) {
        wrongLocationText = text
    }

    func updateLocation(location: LocationAddress?) {
        if let location = location {
            let startingWorksite = worksiteIn
            let changedWorksite = worksiteIn.copy {
                $0.latitude = location.latitude
                $0.longitude = location.longitude
                $0.what3Words = ""
            }
            Task {
                do {
                    try await saveWorksiteChange(
                        startingWorksite,
                        changedWorksite,
                        true
                    )
                    isSavedSubject.value = true
                } catch {
                    // TODO: Show error
                    logger.logError(error)
                }
            }
        }
    }

    func onIncidentQueryChange(_ query: String) {
        queryIncidentsManager.incidentQ.value = query
    }

    func onWrongIncident(
        isIncidentListed: Bool,
        incidentQuery: String,
        selectedIncident: IncidentIdNameType?
    ) {
        var selectedIncidentId: Int64 = -1

        if isIncidentListed,
           let selectedIncident = selectedIncident,
           selectedIncident.name.trim().starts(with: incidentQuery.trim())
        {
            selectedIncidentId = selectedIncident.id
        }

        if selectedIncidentId > 0 {
            if let incidentChange = queryIncidentsManager.incidentLookup[selectedIncidentId] {
                let changeIncidentId = selectedIncidentId
                let startingWorksite = worksiteIn
                let changedWorksite = worksiteIn.copy { $0.incidentId = changeIncidentId }
                Task {
                    do {
                        try await saveWorksiteChange(
                            startingWorksite,
                            changedWorksite,
                            true
                        )

                        incidentSelectManager.setIncident(incidentChange)
                        incidentWorksiteChangeSubject.value =
                        (changeIncidentId, startingWorksite.id)
                    } catch {
                        // TODO: Show error
                        logger.logError(error)
                    }
                }
            }
        } else {
            let wrongIncidentFlag = WorksiteFlag.flag(flag: WorksiteFlagType.wrongIncident)
            commitFlag(wrongIncidentFlag)
        }
    }
}
