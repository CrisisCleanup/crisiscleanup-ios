import Atomics
import Combine
import Foundation

struct IncidentAnnotations {
    let incidentId: Int64
    let filters: CasesFilter
    let annotations: [WorksiteAnnotationMapMark]

    init(
        _ incidentId: Int64,
        _ filters: CasesFilter = CasesFilter(),
        _ annotations: [WorksiteAnnotationMapMark] = [WorksiteAnnotationMapMark]()
    ) {
        self.incidentId = incidentId
        self.filters = filters
        self.annotations = annotations
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
    private let applyGuard = NSLock()

    private let annotationsSubject: any Subject<AnnotationsChangeSet, Never>

    private var applyChangeSet = emptyAnnotationsChangeSet

    private var appliedIds: Set<Int64> = []

    init(_ annotationsSubject: any Subject<AnnotationsChangeSet, Never>) {
        self.annotationsSubject = annotationsSubject
    }

    func onAnnotationStateChange(_ incidentId: Int64, _ filters: CasesFilter) -> Bool {
        applyGuard.withLock {
            let isChange = isChanged(incidentId, filters)
            if isChange {
                let annotations = IncidentAnnotations(incidentId, filters)
                applyChangeSet = AnnotationsChangeSet(
                    annotations: annotations,
                    isClean: true
                )
                appliedIds = []
                annotationsSubject.send(applyChangeSet)
            }
            return isChange
        }
    }

    private func isChanged(_ incidentId: Int64, _ filters: CasesFilter) -> Bool {
        let state = applyChangeSet.annotations
        return state.incidentId != incidentId || state.filters != filters
    }

    func getChange(
        _ incidentId: Int64,
        _ filters: CasesFilter,
        _ annotations: [WorksiteAnnotationMapMark]
    ) throws -> AnnotationsChangeSet {
        var isChanged = false
        var appliedIds: Set<Int64> = []
        applyGuard.withLock {
            appliedIds = self.appliedIds
            isChanged = self.isChanged(incidentId, filters)
        }

        if isChanged {
            throw CancellationError()
        }

        let newAnnotations = annotations.filter {
            !appliedIds.contains($0.source.id)
        }
        let newIds = Set(newAnnotations.map { $0.source.id })
        return AnnotationsChangeSet(
            annotations: IncidentAnnotations(
                incidentId,
                filters,
                annotations
            ),
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
