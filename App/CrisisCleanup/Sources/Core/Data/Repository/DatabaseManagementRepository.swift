public protocol DatabaseManagementRepository {
    func rebuildFts() async
}

class CrisisCleanupDatabaseManagementRepository: DatabaseManagementRepository {

    func rebuildFts() async {
        // TODO: Rebuild FTS tables
    }
}
