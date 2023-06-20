import GRDB
@testable import CrisisCleanup

func initializeTestDb() throws -> (DatabaseQueue, AppDatabase) {
    let dbQueue = try DatabaseQueue(configuration: AppDatabase.makeConfiguration())
    let appDb = try AppDatabase(dbQueue)
    return (dbQueue, appDb)
}
