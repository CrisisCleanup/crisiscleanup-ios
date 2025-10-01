// sourcery: copyBuilder
public struct AppMaintenance: Codable {
    let ftsRebuildVersion: Int64

    init(
        ftsRebuildVersion: Int64 = 0,
    ) {
        self.ftsRebuildVersion = ftsRebuildVersion
    }
}
