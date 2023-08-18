import Combine
import Foundation
import SwiftUI

class CaseFlagsViewModel: ObservableObject {
    private let organizationsRepository: OrganizationsRepository
    private let incidentsRepository: IncidentsRepository
    private let accountDataRepository: AccountDataRepository
    private let addressSearchRepository: AddressSearchRepository
    private let worksiteChangeRepository: WorksiteChangeRepository
    private let incidentSelectManager: IncidentSelector
    private let syncPusher: SyncPusher
    let translator: KeyAssetTranslator
    private let logger: AppLogger

    private let editableWorksite: AnyPublisher<Worksite, Never>
    private let worksiteIn: Worksite
    private let flagsIn: Set<WorksiteFlagType>

    @Published private(set) var incidentWorksiteChange = (0, 0)
    private let incidentWorksiteChangeSubject = CurrentValueSubject<(Int64, Int64), Never>((0, 0))

    @Published private(set) var screenTitle = ""

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
    @Published private var isSavingWorksite = false
    private let isSavingWorksiteSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isSaved = false
    private let isSavedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isEditable = false

    @Published private(set) var nearbyOrganizations: [IncidentOrganization]? = nil

    @Published var otherOrgQ = ""
    @Published private(set) var otherOrgResults = [OrganizationIdName]()

    private let wrongLocationManager: WrongLocationFlagManager
    @Published private(set) var isProcessingLocation = false
    let wrongLocationText: Binding<String>
    @Published private(set) var validCoordinates: LocationAddress? = nil

    private let queryIncidentsManager: QueryIncidentsManager
    // TODO: How to use single binding value compatible with complex SwiftUI views?
    var incidentQBinding: Binding<String>
    @Published private(set) var incidentQ = ""
    @Published private(set) var isLoadingIncidents = false
    @Published private(set) var incidentResults: (String, [IncidentIdNameType]) = ("", [])

    private var subscriptions =  Set<AnyCancellable>()

    init(
        isFromCaseEdit: Bool,
        worksiteProvider: WorksiteProvider,
        editableWorksiteProvider: EditableWorksiteProvider,
        organizationsRepository: OrganizationsRepository,
        incidentsRepository: IncidentsRepository,
        accountDataRepository: AccountDataRepository,
        addressSearchRepository: AddressSearchRepository,
        worksiteChangeRepository: WorksiteChangeRepository,
        incidentSelectManager: IncidentSelector,
        syncPusher: SyncPusher,
        translator: KeyAssetTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.organizationsRepository = organizationsRepository
        self.incidentsRepository = incidentsRepository
        self.accountDataRepository = accountDataRepository
        self.addressSearchRepository = addressSearchRepository
        self.worksiteChangeRepository = worksiteChangeRepository
        self.incidentSelectManager = incidentSelectManager
        self.syncPusher = syncPusher
        self.translator = translator
        logger = loggerFactory.getLogger("add-case-flag")

        let worksiteSubject = isFromCaseEdit
        ? editableWorksiteProvider.editableWorksite
        : worksiteProvider.editableWorksite
        editableWorksite = worksiteSubject.eraseToAnyPublisher()
        worksiteIn = worksiteSubject.value
        flagsIn = Set(worksiteIn.flags?.compactMap { $0.flagType } ?? [])

        let wlm = WrongLocationFlagManager(addressSearchRepository, logger)
        wrongLocationManager = wlm

        let qim = QueryIncidentsManager(incidentsRepository)
        queryIncidentsManager = qim

        wrongLocationText = Binding<String>(
            get: { wlm.wrongLocationText.value },
            set: { wlm.wrongLocationText.value = $0 }
        )

        incidentQBinding = Binding<String>(
            get: { qim.incidentQ.value },
            set: { qim.incidentQ.value = $0 }
        )

        let existingSingularFlags = Set(flagsIn.filter { singleExistingFlags.contains($0) })
        flagFlows = allFlags.filter { !existingSingularFlags.contains($0) }

        screenTitle = "\(translator.t("nav.flag")) (\(worksiteIn.caseNumber))"
    }

    func onViewAppear() {
        subscribeSaveState()
        subscribeEditable()
        subscribeWrongLocationManager()
        subscribeQueryIncidentManager()
        subscribeNearbyOrganizations()
        subscribeOtherOrgResults()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeSaveState() {
        isSavingSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isSaving, on: self)
            .store(in: &subscriptions)
        isSavingWorksiteSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isSavingWorksite, on: self)
            .store(in: &subscriptions)
        isSavedSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isSaved, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeEditable() {
        Publishers.CombineLatest3(
            $isSaving,
            $isSavingWorksite,
            $isSaved
        )
        .map { (b0, b1, b2) in !(b0 || b1 || b2) }
        .receive(on: RunLoop.main)
        .assign(to: \.isEditable, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeWrongLocationManager() {
        wrongLocationManager.isProcessingLocation
            .eraseToAnyPublisher()
            .debounce(
                for: .seconds(0.15),
                scheduler: RunLoop.current
            )
            .receive(on: RunLoop.main)
            .assign(to: \.isProcessingLocation, on: self)
            .store(in: &subscriptions)

        wrongLocationManager.validCoordinates
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.validCoordinates, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeQueryIncidentManager() {
        queryIncidentsManager.isLoading.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.isLoadingIncidents, on: self)
            .store(in: &subscriptions)

        queryIncidentsManager.incidentResults.eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.incidentResults, on: self)
            .store(in: &subscriptions)

        queryIncidentsManager.incidentQ
            .receive(on: RunLoop.main)
            .assign(to: \.incidentQ, on: self)
            .store(in: &subscriptions)
    }

    private let latestNearbyOrganizationsPublisher = LatestAsyncPublisher<[IncidentOrganization]?>()
    private func subscribeNearbyOrganizations() {
        editableWorksite.map { worksite in
            self.latestNearbyOrganizationsPublisher.publisher {
                let coordinates = worksite.coordinates
                return await self.organizationsRepository.getNearbyClaimingOrganizations(
                    coordinates.latitude,
                    coordinates.longitude
                )
            }
        }
        .switchToLatest()
        .receive(on: RunLoop.main)
        .assign(to: \.nearbyOrganizations, on: self)
        .store(in: &subscriptions)
    }

    private func subscribeOtherOrgResults() {
            $otherOrgQ
            .throttle(
                for: .seconds(0.15),
                      scheduler: RunLoop.current,
                      latest: true
            )
            .map {
                $0.isBlank || $0.trim().count < 2
                ? []
                : self.organizationsRepository.getMatchingOrganizations($0.trim())
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

    // TODO: Test coverage. Especially overwriting
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

    private func getSelectedOrganizations(
        _ otherOrgQuery: String,
        _ otherOrganizationsInvolved: OrganizationIdName?
    ) -> [Int64] {
        if let orgName = otherOrganizationsInvolved?.name,
           otherOrgQuery.trim() == orgName.trim() {
            return [otherOrganizationsInvolved!.id]
        }
        return []
    }

    func onUpsetClient(
        notes: String,
        isMyOrgInvolved: Bool?,
        otherOrgQuery: String,
        otherOrganizationInvolved: OrganizationIdName?
    ) {
        let organizations = getSelectedOrganizations(otherOrgQuery, otherOrganizationInvolved)

        let upsetClientFlag = WorksiteFlag.flag(
            flag: WorksiteFlagType.upsetClient,
            notes: notes
        ).copy {
            $0.attr = WorksiteFlag.FlagAttributes(
                involvesMyOrg: isMyOrgInvolved,
                haveContactedOtherOrg: nil,
                organizations:organizations
            )
        }
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
        action: String,
        otherOrgQuery: String,
        otherOrganizationInvolved: OrganizationIdName?
    ) {
        let organizations = getSelectedOrganizations(otherOrgQuery, otherOrganizationInvolved)

        let reportAbuseFlag = WorksiteFlag.flag(
            flag: WorksiteFlagType.reportAbuse,
            notes: notes,
            requestedAction: action
        ).copy {
            $0.attr = WorksiteFlag.FlagAttributes(
                involvesMyOrg: nil,
                haveContactedOtherOrg: isContacted,
                organizations:organizations
            )
        }
        commitFlag(reportAbuseFlag)
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
