import Combine
import Foundation
import GRDB

public class CaseHistoryDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func streamEvents(_ worksiteId: Int64) -> AnyPublisher<[PopulatedCaseHistoryEvent], Never> {
        ValueObservation
            .tracking { db in
                try! CaseHistoryEventRecord
                    .all()
                    .including(required: CaseHistoryEventRecord.attr)
                    .byWorksiteId(worksiteId)
                    .asRequest(of: PopulatedCaseHistoryEvent.self)
                    .fetchAll(db)
            }
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
            .eraseToAnyPublisher()
    }

    func saveEvents(
        _ worksiteId: Int64,
        _ events: [CaseHistoryEventRecord],
        _ eventAttrs: [CaseHistoryEventAttrRecord]
    ) throws {
        try database.saveEvents(worksiteId, events, eventAttrs)
    }
}

extension AppDatabase {
    func saveEvents(
        _ worksiteId: Int64,
        _ events: [CaseHistoryEventRecord],
        _ eventAttrs: [CaseHistoryEventAttrRecord]
    ) throws {
        let eventIds = Set(events.map { $0.id })
        try dbWriter.write{ db in
            try CaseHistoryEventRecord.deleteUnspecified(db, worksiteId, eventIds)
            for record in events {
                try record.upsert(db)
            }
            for record in eventAttrs {
                try record.upsert(db)
            }
        }
    }
}
