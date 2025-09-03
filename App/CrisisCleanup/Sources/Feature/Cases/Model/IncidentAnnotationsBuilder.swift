// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension IncidentAnnotations {
    // struct copy, lets you overwrite specific variables retaining the value of the rest
    // using a closure to set the new values for the copy of the struct
    func copy(build: (inout Builder) -> Void) -> IncidentAnnotations {
        var builder = Builder(original: self)
        build(&builder)
        return builder.toIncidentAnnotations()
    }

    struct Builder {
        var incidentId: Int64
        var filters: CasesFilter
        var changedCase: CaseChangeTime
        var annotations: [WorksiteAnnotationMapMark]
        var denseDescription: DenseMarkDescription
        var isClean: Bool

        fileprivate init(original: IncidentAnnotations) {
            self.incidentId = original.incidentId
            self.filters = original.filters
            self.changedCase = original.changedCase
            self.annotations = original.annotations
            self.denseDescription = original.denseDescription
            self.isClean = original.isClean
        }

        fileprivate func toIncidentAnnotations() -> IncidentAnnotations {
            return IncidentAnnotations(
                incidentId,
                filters,
                changedCase,
                annotations,
                denseDescription,
                isClean: isClean
            )
        }
    }
}
