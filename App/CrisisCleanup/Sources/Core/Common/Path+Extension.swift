extension String {
    var lastPath: String {
        let subPaths = split(separator: "/")
        let lastPart = subPaths.isEmpty ? "" : (subPaths.last ?? "")
        return String(lastPart)
    }
}
