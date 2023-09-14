import Foundation

extension Worksite {
    var coordinates: LatLng { LatLng(latitude, longitude) }

    internal func copyModifiedFlag(
        _ hasFlag: Bool,
        _ flagPredicate: (WorksiteFlag) -> Bool,
        _ flagProducer: () -> WorksiteFlag
    ) -> Worksite {
        let hadFlag = flags?.first(where: { flagPredicate($0) }) != nil
        if hasFlag == hadFlag {
            return self
        }

        var copyFlags = flags ?? []
        if hasFlag {
            copyFlags.append(flagProducer())
        } else {
            copyFlags = copyFlags.filter { !flagPredicate($0) }
        }
        return copy { $0.flags = copyFlags }
    }

    // TODO: Test coverage where unfinished
    func updateWorkTypeStatuses(
        _ workTypeLookup: [String: String],
        _ formFieldLookup: [String: IncidentFormField],
        _ workTypeStatusLookup: [String: WorkTypeStatus],
        createdAt: Date = Date.now
    ) -> Worksite {
        let formData = self.formData ?? [:]
        var workTypeFrequencyLookup = [String: String]()
        for (key, value) in formData {
            let formField = formFieldLookup[key]!
            if formField.isFrequency,
               value.valueString.isNotBlank {
                workTypeFrequencyLookup[formField.parentKey] = value.valueString
            }
        }

        let existingWorkTypeLookup = workTypes
            .sorted(by: { a, b in a.id < b.id })
            .associateBy { $0.workTypeLiteral }

        var newWorkTypes = [WorkType]()
        var keepWorkTypes = [String: WorkType]()
        for (key, value) in formData {
            let formField = formFieldLookup[key]!
            if value.isBooleanTrue,
               formField.parentKey == WorkFormGroupKey,
               let workTypeLiteral = workTypeLookup[key] {
                let recur = workTypeFrequencyLookup[key]?.ifBlank { nil }
                let status = workTypeStatusLookup[workTypeLiteral] ?? .openUnassigned
                let statusLiteral = status.literal
                if let existingWorkType = existingWorkTypeLookup[workTypeLiteral] {
                    let isRecurChanged = recur != existingWorkType.recur
                    keepWorkTypes[workTypeLiteral] = existingWorkType.copy { c in
                        // TODO: Test same literal and changed literal
                        c.statusLiteral = statusLiteral
                        c.nextRecurAt = isRecurChanged ? nil : existingWorkType.nextRecurAt
                        c.recur = recur
                    }
                } else {
                    newWorkTypes.append(
                        WorkType(
                            id: 0,
                            createdAt: createdAt,
                            orgClaim: nil,
                            nextRecurAt: nil,
                            phase: nil,
                            recur: recur,
                            statusLiteral: statusLiteral,
                            workTypeLiteral: workTypeLiteral
                        )
                    )
                }
            }
        }

        // Some work types may appear multiple times (with different IDs)...
        let initialOrder = workTypes.map { $0.workTypeLiteral }
        var copyWorkTypes = existingWorkTypeLookup.values
            .map {
                let index = initialOrder.firstIndex(of: $0.workTypeLiteral) ?? 0
                return (index, $0)
            }
            .sorted(by: { a, b in a.0 <= b.0 })
            .map { $0.1 }
            .compactMap { keepWorkTypes[$0.workTypeLiteral] }
        copyWorkTypes.append(contentsOf: newWorkTypes.sorted(by: { a, b in
            a.workTypeLiteral.localizedCompare(b.workTypeLiteral) == .orderedAscending
        }))

        return copy { $0.workTypes = copyWorkTypes }
    }

    // TODO: Test coverage
    func updateKeyWorkType(_ reference: Worksite) -> Worksite {
        copy {
            $0.keyWorkType = workTypes.matchKeyWorkType(reference)
        }
    }
}

extension Array where Element == WorkType {
    func matchKeyWorkType(_ reference: Worksite) -> WorkType? {
        var keyWorkType: WorkType? = nil
        if let matchWorkType = reference.keyWorkType?.workType {
            keyWorkType = first { $0.workType == matchWorkType }
        }
        return keyWorkType ?? firstOrNil
    }
}
