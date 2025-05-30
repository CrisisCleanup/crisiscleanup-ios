import Foundation

@available(*, deprecated)
struct WorksiteSyncStatRecord : Identifiable, Equatable {
    let id: Int64
    let syncStart: Date
    let targetCount: Int
    let pagedCount: Int
    let successfulSync: Date?
    let attemptedSync: Date?
    let attemptedCounter: Int
    let appBuildVersionCode: Int64
}
