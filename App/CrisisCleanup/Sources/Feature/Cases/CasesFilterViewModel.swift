import Atomics
import Combine
import SwiftUI

class CasesFilterViewModel: ObservableObject {
    private let workTypeStatusRepository: WorkTypeStatusRepository
    private let casesFilterRepository: CasesFilterRepository
    private let incidentSelector: IncidentSelector
    private let incidentsRepository: IncidentsRepository
    private let languageRepository: LanguageTranslationsRepository
    private let locationManager: LocationManager
    let translator: KeyTranslator
    private let logger: AppLogger

    private let isInitialFilterValue = ManagedAtomic(true)

    @Published private(set) var casesFilters: CasesFilter = CasesFilter()
    @Published var filterStatuses = ObservableBoolDictionary()
    @Published var filterFlags = ObservableBoolDictionary()
    @Published var filterWorkTypes = ObservableBoolDictionary()
    @Published var filterCreatedAtStart: Date? = nil
    @Published var filterCreatedAtEnd: Date? = nil
    @Published var filterUpdatedAtStart: Date? = nil
    @Published var filterUpdatedAtEnd: Date? = nil

    @Published private(set) var workTypeStatuses = [WorkTypeStatus]()

    @Published private(set) var worksiteFlags = [WorksiteFlagType]()

    @Published private(set) var workTypes = [String]()

    let collapsibleFilterSections: [CollapsibleFilterSection] = [
        .distance,
        .general,
        .personalInfo,
        .flags,
        .work,
        .dates
    ]
    let filterSectionTitles: [String]
    let indexedTitles: [(Int, String)]

    let distanceOptions: [(Double, String)]
    private var distanceOptionCached = ManagedAtomic(AtomicDoubleOptional())

    @Published var showExplainLocationPermssion = false
    @Published var hasInconsistentDistanceFilter = false

    private var subscriptions = Set<AnyCancellable>()

    init(
        workTypeStatusRepository: WorkTypeStatusRepository,
        casesFilterRepository: CasesFilterRepository,
        incidentSelector: IncidentSelector,
        incidentsRepository: IncidentsRepository,
        languageRepository: LanguageTranslationsRepository,
        locationManager: LocationManager,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.workTypeStatusRepository = workTypeStatusRepository
        self.casesFilterRepository = casesFilterRepository
        self.incidentSelector = incidentSelector
        self.incidentsRepository = incidentsRepository
        self.languageRepository = languageRepository
        self.locationManager = locationManager
        self.translator = translator
        logger = loggerFactory.getLogger("filter-cases")

        let sectionTranslationKey: [CollapsibleFilterSection: String] = [
            .distance: "worksiteFilters.distance",
            .general: "worksiteFilters.general",
            .personalInfo: "worksiteFilters.personal_info",
            .flags: "worksiteFilters.flags",
            .work: "worksiteFilters.work",
            .dates: "worksiteFilters.dates",
        ]
        filterSectionTitles = collapsibleFilterSections.map { section in
            if let sectionKey = sectionTranslationKey[section] {
                return translator.t(sectionKey)
            }
            return ""
        }
        indexedTitles = Array(filterSectionTitles.enumerated())

        distanceOptions = [
            (0, translator.t("worksiteFilters.any_distance")),
            (0.3, translator.t("worksiteFilters.point_3_miles")),
            (1, translator.t("worksiteFilters.one_mile")),
            (5, translator.t("worksiteFilters.five_miles")),
            (20, translator.t("worksiteFilters.twenty_miles")),
            (50, translator.t("worksiteFilters.fifty_miles")),
            (100, translator.t("worksiteFilters.one_hundred_miles")),
        ]

        worksiteFlags = WorksiteFlagType.allCases.sorted(by: { a, b in
            a.literal.localizedCompare(b.literal) == .orderedAscending
        })
    }

    func onViewAppear() {
        subscribeFilterData()
        subscribeLocationStatus()
    }

    func onViewDisappear() {
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeFilterData() {
        casesFilterRepository.casesFiltersLocation
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink { (filters, _) in
                if !filters.isDefault,
                   self.isInitialFilterValue.exchange(false, ordering: .sequentiallyConsistent) {
                    self.casesFilters = filters

                    let statuses = self.filterStatuses
                    for workTypeStatus in filters.workTypeStatuses {
                        statuses[workTypeStatus.literal] = true
                    }

                    let flags = self.filterFlags
                    for flag in filters.worksiteFlags {
                        flags[flag.literal] = true
                    }

                    let workTypes = self.filterWorkTypes
                    for workType in filters.workTypes {
                        workTypes[workType] = true
                    }

                    self.filterCreatedAtStart = filters.createdAt?.start
                    self.filterCreatedAtEnd = filters.createdAt?.end
                    self.filterUpdatedAtStart = filters.updatedAt?.start
                    self.filterUpdatedAtEnd = filters.updatedAt?.end
                }
            }
            .store(in: &subscriptions)

        $filterStatuses
            .sink { _ in
                let statuses = self.filterStatuses.data.filter { $0.value }
                    .map { statusFromLiteral($0.key) }
                self.changeFilters {
                    $0.workTypeStatuses = Set(statuses)
                }
            }
            .store(in: &subscriptions)

        $filterFlags
            .sink { _ in
                let flags = self.filterFlags.data.filter { $0.value }
                    .compactMap { flagFromLiteral( $0.key ) }
                self.changeFilters {
                    $0.worksiteFlags = flags
                }
            }
            .store(in: &subscriptions)

        $filterWorkTypes
            .sink { _ in
                let workTypes = self.filterWorkTypes.data.filter { $0.value }
                    .map { $0.key }
                self.changeFilters {
                    $0.workTypes = Set(workTypes)
                }
            }
            .store(in: &subscriptions)

        func getDateRange(_ start: Date?, _ end: Date?) -> CasesFilter.DateRange? {
            start == nil || end == nil
            ? nil
            : CasesFilter.DateRange(
                start: start!,
                end: end!
            )
        }

        Publishers.CombineLatest(
            $filterCreatedAtStart,
            $filterCreatedAtEnd
        )
        .sink(receiveValue: { start, end in
            self.changeFilters {
                $0.createdAt = getDateRange(start, end)
            }
        })
        .store(in: &subscriptions)

        Publishers.CombineLatest(
            $filterUpdatedAtStart,
            $filterUpdatedAtEnd
        )
        .sink(receiveValue: { start, end in
            self.changeFilters {
                $0.updatedAt = getDateRange(start, end)
            }
        })
        .store(in: &subscriptions)

        workTypeStatusRepository.workTypeStatusFilterOptions
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .assign(to: \.workTypeStatuses, on: self)
            .store(in: &subscriptions)

        incidentSelector.incidentId
            .eraseToAnyPublisher()
        // TODO: switchMap/mapLatest
            .map { id in self.incidentsRepository.streamIncident(id).eraseToAnyPublisher() }
            .switchToLatest()
            .eraseToAnyPublisher()
            .map { incident in
                if let formFields = incident?.formFields {
                    let formFieldRootNode = FormFieldNode.buildTree(
                        formFields,
                        self.languageRepository
                    )
                        .map { $0.flatten() }

                    if let node = formFieldRootNode.first(where: { $0.fieldKey == WorkFormGroupKey }) {
                        return node.children.filter { $0.parentKey == WorkFormGroupKey }
                            .map { $0.formField.selectToggleWorkType }
                            .sorted(by: { a, b in a.localizedCompare(b) == .orderedAscending })
                    }
                }
                return []
            }
            .receive(on: RunLoop.main)
            .assign(to: \.workTypes, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeLocationStatus() {
        locationManager.$locationPermission
            .sink { _ in
                if self.locationManager.hasLocationAccess {
                    if let cachedDistance = self.distanceOptionCached.exchange(AtomicDoubleOptional(), ordering: .relaxed).value {
                        self.changeFilters {
                            $0.distance = cachedDistance
                        }
                    }
                }
            }
            .store(in: &subscriptions)

        Publishers.CombineLatest(
            locationManager.$locationPermission,
            $casesFilters
        )
        .map { (_, filters) in
            filters.hasDistanceFilter && !self.locationManager.hasLocationAccess
        }
        .receive(on: RunLoop.main)
        .assign(to: \.hasInconsistentDistanceFilter, on: self)
        .store(in: &subscriptions)
    }

    func requestLocationAccess() -> Bool {
        locationManager.requestLocationAccess()
    }

    private func changeDistanceFilter() {
        if let distance = distanceOptionCached.exchange(
            AtomicDoubleOptional(),
            ordering: .sequentiallyConsistent
        ).value {
            changeDistanceFilter(distance)
        }
    }

    private func changeDistanceFilter(_ distance: Double) {
        changeFilters { $0.distance = distance }
    }

    func tryChangeDistanceFilter(_ distance: Double) -> Bool {
        if requestLocationAccess() {
            changeDistanceFilter(distance)
            return true
        }

        distanceOptionCached.store(AtomicDoubleOptional(distance), ordering: .relaxed)

        if locationManager.isDeniedLocationAccess {
            showExplainLocationPermssion = true
        }
        return false
    }

    func changeFilters(_ filters: CasesFilter) {
        casesFilters = filters
    }

    func changeFilters(build: (inout CasesFilter.Builder) -> Void) {
        changeFilters(casesFilters.copy(build: build))
    }

    func clearFilters() {
        let filters = CasesFilter()
        filterStatuses = ObservableBoolDictionary()
        filterFlags = ObservableBoolDictionary()
        filterWorkTypes = ObservableBoolDictionary()
        changeFilters(filters)
        applyFilters(filters)
    }

    func applyFilters(_ filters: CasesFilter) {
        casesFilterRepository.changeFilters(filters)
    }
}

enum CollapsibleFilterSection {
    case distance,
         general,
         personalInfo,
         flags,
         work,
         dates
}
