import Atomics
import Combine
import Foundation

struct IncidentAnnotations {
    let incidentId: Int64
    let filters: CasesFilter
    let changedCase: CaseChangeTime
    let annotations: [WorksiteAnnotationMapMark]
    let isClean: Bool

    init(
        _ incidentId: Int64,
        _ filters: CasesFilter = CasesFilter(),
        _ changedCase: CaseChangeTime = CaseChangeTime(ExistingWorksiteIdentifierNone),
        _ annotations: [WorksiteAnnotationMapMark] = [WorksiteAnnotationMapMark](),
        isClean: Bool = false
    ) {
        self.incidentId = incidentId
        self.filters = filters
        self.changedCase = changedCase
        self.annotations = annotations
        self.isClean = isClean
    }
}

// sourcery: copyBuilder, skipCopyInit
struct AnnotationsChangeSet {
    let annotations: IncidentAnnotations
    let isClean: Bool
    let newAnnotations: [WorksiteAnnotationMapMark]
    let newAnnotationIds: Set<Int64>

    init(
        annotations: IncidentAnnotations = emptyIncidentAnnotations,
        isClean: Bool = false,
        newAnnotations: [WorksiteAnnotationMapMark] = [],
        newAnnotationIds: Set<Int64> = []

    ) {
        self.annotations = annotations
        self.isClean = isClean
        self.newAnnotations = newAnnotations
        self.newAnnotationIds = newAnnotationIds
    }
}

let emptyIncidentAnnotations = IncidentAnnotations(EmptyIncident.id)
let emptyAnnotationsChangeSet = AnnotationsChangeSet()

class MapAnnotationsExchanger {
    private let applyGuard = NSRecursiveLock()

    private let annotationsSubject: any Subject<AnnotationsChangeSet, Never>

    private var applyChangeSet = emptyAnnotationsChangeSet

    private var appliedIds: Set<Int64> = []

    init(_ annotationsSubject: any Subject<AnnotationsChangeSet, Never>) {
        self.annotationsSubject = annotationsSubject
    }

    func onClean(
        _ incidentId: Int64,
        _ filters: CasesFilter,
        _ changedCase: CaseChangeTime
    ) {
        let annotations = IncidentAnnotations(incidentId, filters, changedCase)
        applyGuard.withLock {
            applyChangeSet = AnnotationsChangeSet(
                annotations: annotations,
                isClean: true
            )
            appliedIds = []
            annotationsSubject.send(applyChangeSet)
        }
    }

    func onAnnotationStateChange(
        _ incidentId: Int64,
        _ filters: CasesFilter,
        _ changedCase: CaseChangeTime
    ) -> Bool {
        applyGuard.withLock {
            if isChanged(incidentId, filters, changedCase) {
                onClean(incidentId, filters, changedCase)
                return true
            }
            return false
        }
    }

    private func isChanged(
        _ incidentId: Int64,
        _ filters: CasesFilter,
        _ changedCase: CaseChangeTime
    ) -> Bool {
        let state = applyChangeSet.annotations
        return state.incidentId != incidentId ||
        state.filters != filters ||
        state.changedCase != changedCase
    }

    func getChange(_ incidentAnnotations: IncidentAnnotations) throws -> AnnotationsChangeSet {
        var isChanged = false
        var appliedIds: Set<Int64> = []
        applyGuard.withLock {
            if incidentAnnotations.isClean {
                self.appliedIds = []
            }
            appliedIds = self.appliedIds
            isChanged = self.isChanged(
                incidentAnnotations.incidentId,
                incidentAnnotations.filters,
                incidentAnnotations.changedCase,
            )
        }

        if isChanged {
            throw CancellationError()
        }

        let newAnnotations = incidentAnnotations.annotations.filter {
            !appliedIds.contains($0.source.id)
        }
        let newIds = Set(newAnnotations.map { $0.source.id })
        return AnnotationsChangeSet(
            annotations: incidentAnnotations,
            isClean: incidentAnnotations.isClean,
            newAnnotations: newAnnotations,
            newAnnotationIds: newIds
        )
    }

    func onApplied(_ changes: AnnotationsChangeSet) {
        applyGuard.withLock {
            if applyChangeSet.annotations.incidentId == changes.annotations.incidentId &&
                applyChangeSet.annotations.filters == changes.annotations.filters {
                appliedIds = appliedIds.union(changes.newAnnotationIds)
            }
        }
    }
}
