import Foundation

// Updates to below (and related) must pass regression tests.
// Think through any and all data changes carefully and completely in terms of
// - Local propagation
// - Global propagation
// - Local consistency
// - Global consistency
// - Fully applied deltas
// - Partially applied deltas

class WorksiteChangeSetOperator {
    // TODO: Write tests
    func getNewSet(_ snapshot: WorksiteSnapshot) -> WorksiteChangeSet {
        let coreB = snapshot.core

        let worksitePush = NetworkWorksitePush(
            id: nil,
            address: coreB.address,
            autoContactFrequencyT: coreB.autoContactFrequencyT,
            caseNumber: nil,
            city: coreB.city,
            county: coreB.county,
            email: coreB.email ?? "",
            // New does not have favorite. Member of my org makes a followup request.
            favorite: nil,
            formData: coreB.networkFormData,
            incident: coreB.incidentId,
            keyWorkType: nil,
            location: coreB.pointLocation,
            name: coreB.name,
            // Notes are followup requests.
            phone1: coreB.phone1,
            phone1Notes: coreB.phone1Notes,
            phone2: coreB.phone2,
            phone2Notes: coreB.phone2Notes,
            plusCode: coreB.plusCode,
            postalCode: coreB.postalCode,
            reportedBy: coreB.reportedBy,
            state: coreB.state,
            svi: nil,
            updatedAt: coreB.updatedAt ?? Date.now,
            what3words: "",
            workTypes: nil,

            skipDuplicateCheck: true,
            sendSms: true
        )

        let workTypeChanges = snapshot.workTypes
            .filter { $0.workType.orgClaim != nil }
            .map {
                $0.workType.claimNew(
                    $0.localId,
                    $0.workType.createdAt ?? worksitePush.updatedAt
                )
            }

        return WorksiteChangeSet(
            updatedAtFallback: worksitePush.updatedAt,
            worksite: worksitePush,
            isOrgMember: coreB.isAssignedToOrgMember ? true : nil,
            extraNotes: snapshot.getNewNetworkNotes([:]),
            flagChanges: (snapshot.flags.map { ($0.localId, $0.asNetworkFlag()) }, []),
            workTypeChanges: workTypeChanges
        )
    }

    // TODO: Write tests
    func getChangeSet(
        base: NetworkWorksiteFull,
        start: WorksiteSnapshot,
        change: WorksiteSnapshot,
        flagIdLookup: [Int64: Int64],
        noteIdLookup: [Int64: Int64],
        workTypeIdLookup: [Int64: Int64]
    ) -> WorksiteChangeSet {
        let coreA = start.core
        let coreB = change.core

        let updatedAt = coreB.updatedAt ?? Date.now

        let (newWorkTypes, workTypeChanges, _) = base.getWorkTypeChanges(
            start.workTypes,
            change.workTypes,
            updatedAt,
            workTypeIdLookup
        )

        // TODO: Is this correct? And complete? Select one by default if no match?
        let keyWorkType = {
            if let localId = coreB.keyWorkTypeId {
                return change.matchingWorkTypeOrNil(localId)
            }
            return nil
        }()

        let formDataPush = base.getFormDataChanges(coreA.formData, coreB.formData)
        let worksitePush = base.getCoreChange(coreA, coreB, formDataPush, keyWorkType, updatedAt)

        let isAssignedToOrgMember = base.getFavoriteChange(coreA, coreB)

        let addNotes = change.getNewNetworkNotes(noteIdLookup)
        let newNotes = base.filterDuplicateNotes(addNotes)

        let flagChanges = base.getFlagChanges(start.flags, change.flags, flagIdLookup)

        // TODO: Review data consistency rules and guarantee correctness.
        //       This applies to both form data and work types.
        //       - At least one work type must be specified.
        //         This should not be an issue if local guarantees each snapshot has at least one work type.
        //       - Fallback to keeping at least one of the existing work types

        return WorksiteChangeSet(
            updatedAtFallback: updatedAt,
            worksite: worksitePush,
            isOrgMember: isAssignedToOrgMember,
            extraNotes: newNotes,
            flagChanges: flagChanges,
            newWorkTypes: newWorkTypes,
            workTypeChanges: workTypeChanges
        )
    }
}

extension NetworkWorksiteFull {
    internal func getCoreChange(
        _ coreA: CoreSnapshot,
        _ coreB: CoreSnapshot,
        _ formDataPush: [KeyDynamicValuePair],
        _ keyWorkTypePush: NetworkWorkType?,
        _ updatedAtPush: Date
    ) -> NetworkWorksitePush? {
        if (
            coreA.copy {
                $0.updatedAt = coreB.updatedAt
                $0.isAssignedToOrgMember = coreB.isAssignedToOrgMember
            } == coreB
        ) {
            return nil
        }

        let isLocationChange = coreA.latitude != coreB.latitude ||
        coreA.longitude != coreB.longitude
        let locationPush = isLocationChange ? coreB.pointLocation : location

        return NetworkWorksitePush(
            id: id,
            address: address.change(coreA.address, coreB.address),
            autoContactFrequencyT: autoContactFrequencyT.change(
                coreA.autoContactFrequencyT,
                coreB.autoContactFrequencyT
            ),
            caseNumber: caseNumber,
            city: city.change(coreA.city, coreB.city),
            county: baseChange(county, coreA.county, coreB.county) ?? "",
            email: baseChange(email, coreA.email, coreB.email) ?? "",
            // Member of my org/favorite change is performed in a followup call
            favorite: favorite,
            formData: formDataPush,
            incident: coreB.incidentId == coreA.incidentId ? incident : coreB.incidentId,
            keyWorkType: keyWorkTypePush,
            location: locationPush,
            name: name.change(coreA.name, coreB.name),
            phone1: phone1.change(coreA.phone1, coreB.phone1),
            phone1Notes: baseChange(phone1Notes, coreA.phone1Notes, coreB.phone1Notes),
            phone2: baseChange(phone2, coreA.phone2, coreB.phone2) ?? "",
            phone2Notes: baseChange(phone2Notes, coreA.phone2Notes, coreB.phone2Notes),
            plusCode: baseChange(plusCode, coreA.plusCode, coreB.plusCode)?.ifBlank { nil },
            postalCode: baseChange(postalCode, coreA.postalCode, coreB.postalCode),
            reportedBy: reportedBy,
            state: state.change(coreA.state, coreB.state),
            svi: svi,
            updatedAt: updatedAtPush,
            what3words: baseChange(what3words, coreA.what3Words, coreB.what3Words) ?? "",
            // TODO: Review if this works
            workTypes: [],

            skipDuplicateCheck: true,
            sendSms: nil
        )
    }

    internal func getFavoriteChange(
        _ coreA: CoreSnapshot,
        _ coreB: CoreSnapshot
    ) -> Bool? {
        let isFavoriteA = coreA.isAssignedToOrgMember
        let isFavoriteB = coreB.isAssignedToOrgMember
        return isFavoriteA == isFavoriteB || isFavoriteB == (favorite != nil) ? nil : isFavoriteB
    }

    /**
     * Determines changes in flags between snapshots relative to [NetworkWorksiteFull.flags]
     *
     * New flags are ignored if existing networked flags have matching [NetworkFlag.reasonT].
     * Local flags should assume networked flags where reason matches.
     *
     * Flags are marked for deletion only where existing networked flags have matching [NetworkFlag.reasonT].
     *
     * @param flagIdLookup Local ID to network ID. Missing in map or non-positive network ID indicates not yet successfully synced to backend.
     * @return New flags and existing flag IDs to delete.
     */
    internal func getFlagChanges(
        _ start: [FlagSnapshot],
        _ change: [FlagSnapshot],
        _ flagIdLookup: [Int64: Int64]
    ) -> ([(Int64, NetworkFlag)], [Int64]) {
        func updateNetworkIds(_ snapshots: [FlagSnapshot]) -> [FlagSnapshot] {
            snapshots.map { fs in
                var snapshot = fs
                if fs.flag.id <= 0 {
                    if let networkId = flagIdLookup[fs.localId] {
                        snapshot = fs.copy { s in
                            s.flag = s.flag.copy { f in
                                f.id = networkId
                            }
                        }
                    }
                }
                return snapshot
            }
        }

        let startUpdated = updateNetworkIds(start)
        let changeUpdated = updateNetworkIds(change)

        let startReasons = Set(startUpdated.map { $0.flag.reasonT })
        let existingReasons = Set(flags.map { $0.reasonT })

        let newFlags = changeUpdated
            .filter { $0.flag.id <= 0 }
            .filter { !existingReasons.contains($0.flag.reasonT) }
            .map { ($0.localId, $0.asNetworkFlag()) }

        let keepReasons = Set(changeUpdated.map { $0.flag.reasonT })
        let deleteReasons = Set(startReasons
            .filter { !keepReasons.contains($0) })
        let deleteFlagIds = flags
            .filter { deleteReasons.contains($0.reasonT) }
        // Incoming network ID is always defined
            .map { $0.id! }

        return (newFlags, deleteFlagIds)
    }

    internal func getFormDataChanges(
        _ start: [String: DynamicValue],
        _ change: [String: DynamicValue]
    ) -> [KeyDynamicValuePair] {
        if (start == change) {
            return formData
        }

        let newFormData = change.compactMap {
            start.keys.contains($0.key) ? nil : KeyDynamicValuePair($0.key, $0.value)
        }
        let deletedFormData = start.compactMap {
            change.keys.contains($0.key) ? nil : $0.key
        }
        let crossChangeFormData = change.compactMap {
            start.keys.contains($0.key) ? $0 : nil
        }
        let unchangedFormData = crossChangeFormData
            .compactMap { changeData in
                let crossStartValue = start[changeData.key]!
                let changeValue = changeData.value
                return changeValue.isBoolEqual(crossStartValue) ||
                changeValue.isStringEqual(crossStartValue) ? changeData : nil
            }
            .associate { ($0.key, $0.value) }
        let changedFormData = crossChangeFormData
            .compactMap { unchangedFormData.keys.contains($0.key) ? nil : $0 }
            .associate { ( $0.key, $0.value) }

        if (deletedFormData.isEmpty && newFormData.isEmpty && changedFormData.isEmpty) {
            return formData
        }

        var mutableFormData = formData
            .associate { ($0.key, $0.value) }
        deletedFormData.forEach { mutableFormData.removeValue(forKey: $0) }
        newFormData.forEach { mutableFormData[$0.key] = $0.value }
        changedFormData.forEach { mutableFormData[$0.key] = $0.value }
        unchangedFormData.forEach { fd in
            // No change between snapshots implies existing values are fine (even if non-existent).
            // If previous snapshots were applied successfully these cases shouldn't exist.
            // Ignore edge cases when this exists as trying to determine intention is highly improbable.
        }

        return mutableFormData
            .map { KeyDynamicValuePair($0.key, $0.value) }
            .sorted { a, b in a.key.localizedCompare(b.key) == .orderedAscending }
    }

    internal func filterDuplicateNotes(
        _ addNotes: [(Int64, NetworkNote)],
        _ matchDuration: TimeInterval = 12.hours
    ) -> [(Int64, NetworkNote)] {
        let existingNotes = notes.filter { $0.note?.isNotBlank == true }
            .associateBy { $0.note!.trim().lowercased() }
        return addNotes.filter { (_, addNote) in
            if let matchingNote = existingNotes[addNote.note?.trim().lowercased() ?? ""] {
                let timeSpan = addNote.createdAt.timeIntervalSince1970 - matchingNote.createdAt.timeIntervalSince1970
                if (abs(timeSpan) < matchDuration) {
                    return false
                }
            }
            return true
        }
    }

    internal func getWorkTypeChanges(
        _ start: [WorkTypeSnapshot],
        _ change: [WorkTypeSnapshot],
        _ changedAt: Date,
        _ workTypeIdLookup: [Int64: Int64] = [:]
    ) -> ([String: WorkTypeChange], [WorkTypeChange], [Int64]) {
        let existingWorkTypes = newestWorkTypes.associate {
            let workTypeCopy = WorkTypeSnapshot.WorkType(
                // Incoming network ID is always defined
                id: $0.id!,
                status: $0.status,
                workType: $0.workType,
                createdAt: $0.createdAt,
                orgClaim: $0.orgClaim,
                nextRecurAt: $0.nextRecurAt,
                phase: $0.phase,
                recur: $0.recur
            )
            return ($0.workType, workTypeCopy)
        }

        // TODO: Add test where coverage is lacking. Start,change (not) in lookup,existing.
        func updateNetworkIds(_ snapshots: [WorkTypeSnapshot]) -> [WorkTypeSnapshot] {
            snapshots.map { wts in
                var snapshot = wts
                var changeNetworkId = wts.workType.id
                if changeNetworkId <= 0 {
                    if let networkId = workTypeIdLookup[wts.localId] {
                        changeNetworkId = networkId
                    }
                }
                if changeNetworkId <= 0 {
                    if let existingWorkType = existingWorkTypes[wts.workType.workType] {
                        changeNetworkId = existingWorkType.id
                    }
                }
                if wts.workType.id != changeNetworkId {
                    snapshot = wts.copy { s in
                        s.workType = wts.workType.copy { w in
                            w.id = changeNetworkId
                        }
                    }
                }
                return snapshot
            }
        }

        let startMap = updateNetworkIds(start).associateBy { $0.workType.workType }
        let changeMap = updateNetworkIds(change).associateBy { $0.workType.workType }

        let newWorkTypes = changeMap
            .filter { $0.value.workType.id <= 0 }
            .map {
                WorkTypeChange(
                    localId: $0.value.localId,
                    networkId: -1,
                    workType: $0.value.workType,
                    changedAt: changedAt,
                    isClaimChange: true,
                    isStatusChange: true
                )
            }

        let deletedWorkTypes = startMap
            .filter { !changeMap.keys.contains($0.key) }
            .compactMap { existingWorkTypes[$0.key]?.id }

        let changedWorkTypes = changeMap
            .map {
                let localId = $0.value.localId
                if let crossStartSnapshot = startMap[$0.key] {
                    return $0.value.workType.changeFrom(crossStartSnapshot.workType, localId, changedAt)
                }
                if let crossExisting = existingWorkTypes[$0.key] {
                    return $0.value.workType.changeFrom(crossExisting, localId, changedAt)
                }
                return nil
            }
            .compactMap { $0?.hasChange == true ? $0 : nil }

        if (newWorkTypes.isEmpty && deletedWorkTypes.isEmpty && changedWorkTypes.isEmpty) {
            return ([:], [], [])
        }

        let modified = {
            var tempWorkTypes = newWorkTypes.associateBy { $0.workType.workType }
            changedWorkTypes.forEach {
                tempWorkTypes[$0.workType.workType] = $0
            }

            return tempWorkTypes.compactMap {
                let existingWorkType = existingWorkTypes[$0.key]
                if (existingWorkType == nil) {
                    return $0.value
                }

                let existing = existingWorkType!
                let localId = $0.value.localId
                if let changeTo = $0.value.workType.changeFrom(existing, localId, changedAt) {
                    let networkId = existing.id
                    return changeTo.copy { c in
                        c.networkId = networkId
                        c.workType = changeTo.workType.copy { wt in
                            wt.id = networkId
                            wt.createdAt = existing.createdAt
                            wt.nextRecurAt = existing.nextRecurAt
                            wt.phase = existing.phase
                            wt.recur = existing.recur
                        }
                    }
                }

                return nil
            }
            .filter { $0.hasChange }
        }()
        let create = modified.filter { $0.networkId <= 0 }
            .associateBy { $0.workType.workType }
        let changing = modified.filter { $0.networkId > 0 }

        return (create, changing, deletedWorkTypes)
    }
}
