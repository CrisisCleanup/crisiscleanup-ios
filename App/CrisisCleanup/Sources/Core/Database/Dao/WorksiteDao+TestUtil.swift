extension WorksiteDao {
    internal func getLocalWorksite(_ id: Int64) throws -> PopulatedLocalWorksite? {
        try reader.read { db in try self.fetchLocalWorksite(db, id) }
    }

    internal func getPopulatedWorksite(_ id: Int64) throws -> PopulatedWorksite? {
        try reader.read { db in
            try WorksiteRootRecord
                .filter(id: id)
                .including(required: WorksiteRootRecord.worksite)
                .including(all: WorksiteRootRecord.workTypes)
                .asRequest(of: PopulatedWorksite.self)
                .fetchOne(db)
        }
    }

    internal func getWorksites(_ incidentId: Int64) throws -> [PopulatedWorksite] {
        try reader.read { db in
            try WorksiteRootRecord
                .all()
                .byIncidentId(incidentId)
                .including(required: WorksiteRootRecord.worksite.orderByUpdatedAtDescIdDesc())
                .including(all: WorksiteRootRecord.workTypes)
                .asRequest(of: PopulatedWorksite.self)
                .fetchAll(db)
        }
    }

    internal func getWorksiteFiles(_ id: Int64) throws -> PopulatedWorksiteFiles? {
        try reader.read { db in try self.fetchWorksiteFiles(db, id) }
    }
}
