/**
 * Determines if the current value is different from [from]
 *
 * - Returns nil if there is no change in value or [self] otherwise.
 * nil indicates a reference value should be used and non-nil indicates the returned value should be used.
 */
extension String {
    fileprivate func diffFrom(_ from: String?) -> String? {
        self.trim() == (from?.trim() ?? "") ? nil : self
    }

    internal func change(_ from: String, _ to: String) -> String {
        to.diffFrom(from) ?? self
    }
}

internal func baseChange(_ base: String?, _ from: String?, _ to: String?) -> String? {
    if base == nil {
        return to?.diffFrom(from)
    } else {
        let nFrom = from?.trim() ?? ""
        let nTo = to?.trim() ?? ""
        return nFrom == nTo ? base : to
    }
}
