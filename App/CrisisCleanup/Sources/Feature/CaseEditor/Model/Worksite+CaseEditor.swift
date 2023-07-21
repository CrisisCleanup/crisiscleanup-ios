extension Worksite {
    var coordinates: LatLng { LatLng(latitude, longitude) }

    func copyModifiedFlags(
        hasFlag: Bool,
        flagPredicate: (WorksiteFlag) -> Bool,
        flagProducer: () -> WorksiteFlag
    ) -> [WorksiteFlag]? {
        let outFlags = flags
        let hadFlag = outFlags?.first(where: { flagPredicate($0) }) != nil
        if (hasFlag == hadFlag) {
            return outFlags
        }

        var copyFlags = Array(outFlags ?? [])
        if (hasFlag) {
            copyFlags.append(flagProducer())
        } else {
            copyFlags = copyFlags.compactMap { flagPredicate($0) ? nil : $0 }
        }
        return copyFlags
    }
}
