import Combine
import Foundation
import GRDB

public class IncidentDataSyncParameterDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    // TODO: Additional
}
