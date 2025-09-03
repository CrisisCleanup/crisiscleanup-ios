import Atomics
import Combine
import Foundation

// sourcery: copyBuilder, skipCopyInit
struct IncidentAnnotations: Equatable {
    let incidentId: Int64
    let filters: CasesFilter
    let changedCase: CaseChangeTime
    let annotations: [WorksiteAnnotationMapMark]
    let denseDescription: DenseMarkDescription
    let isClean: Bool

    init(
        _ incidentId: Int64,
        _ filters: CasesFilter = CasesFilter(),
        _ changedCase: CaseChangeTime = CaseChangeTime(ExistingWorksiteIdentifierNone),
        _ annotations: [WorksiteAnnotationMapMark] = [WorksiteAnnotationMapMark](),
        _ denseDescription: DenseMarkDescription = EmptyDenseMarkDescription,
        isClean: Bool = false
    ) {
        self.incidentId = incidentId
        self.filters = filters
        self.changedCase = changedCase
        self.annotations = annotations
        self.denseDescription = denseDescription
        self.isClean = isClean
    }
}

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

    private func applyCleanState(_ annotations: IncidentAnnotations) {
        applyGuard.withLock {
            applyChangeSet = AnnotationsChangeSet(
                annotations: annotations,
                isClean: true
            )
            appliedIds = []
            annotationsSubject.send(applyChangeSet)
        }
    }

    func onClean(
        _ incidentId: Int64,
        _ filters: CasesFilter,
        _ changedCase: CaseChangeTime,
        denseDescription: DenseMarkDescription =  EmptyDenseMarkDescription,
    ) {
        let annotations = IncidentAnnotations(
            incidentId,
            filters,
            changedCase,
            [],
            denseDescription,
        )
        applyCleanState(annotations)
    }

    func onCleanStateChange(
        _ incidentId: Int64,
        _ filters: CasesFilter,
        _ changedCase: CaseChangeTime
    ) {
        applyGuard.withLock {
            if isCleanStateChange(incidentId, filters, changedCase) {
                onClean(incidentId, filters, changedCase)
            }
        }
    }

    private func isCleanStateChange(
        _ incidentId: Int64,
        _ filters: CasesFilter,
        _ changedCase: CaseChangeTime,
        denseDescription: DenseMarkDescription? =  nil,
    ) -> Bool {
        let state = applyChangeSet.annotations
        let isDenseChanged = if let denseDescription = denseDescription {
            state.denseDescription != denseDescription
        } else {
            false
        }

        return state.incidentId != incidentId ||
        state.filters != filters ||
        state.changedCase != changedCase ||
        isDenseChanged
    }

    func exchange(_ incidentAnnotations: IncidentAnnotations) throws -> AnnotationsChangeSet {
        var isCleanChange = false
        var appliedIds: Set<Int64> = []
        applyGuard.withLock {
            if incidentAnnotations.isClean {
                self.appliedIds = []
            }
            appliedIds = self.appliedIds
            isCleanChange = self.isCleanStateChange(
                incidentAnnotations.incidentId,
                incidentAnnotations.filters,
                incidentAnnotations.changedCase,
                denseDescription: incidentAnnotations.denseDescription,
            )
        }

        if isCleanChange {
            let annotations = incidentAnnotations.annotations
            let cleanState = incidentAnnotations.copy {
                $0.isClean = true
            }
            applyCleanState(cleanState)
            return AnnotationsChangeSet(
                annotations: cleanState,
                isClean: true,
                newAnnotations: annotations,
                newAnnotationIds: Set(annotations.map { $0.source.id }),
            )
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
