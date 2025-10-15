import Combine
import GRDB

public class LocalImageDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func getNetworkFileLocalImage(_ id: Int64) -> NetworkFileLocalImageRecord? {
        try! reader.read { db in
            try NetworkFileLocalImageRecord
                .filter(id: id)
                .fetchOne(db)
        }
    }

    func getLocalImage(_ id: Int64) -> WorksiteLocalImageRecord? {
        try! reader.read { db in
            try WorksiteLocalImageRecord
                .filter(id: id)
                .fetchOne(db)
        }
    }

    func streamLocalImageUrl(_ id: Int64) -> AnyPublisher<String?, Never> {
        ValueObservation
            .tracking({ db in
                try WorksiteLocalImageRecord
                    .all()
                    .selectUriColumn()
                    .filter(id: id)
                    .asRequest(of: String.self)
                    .fetchOne(db)
            })
            .removeDuplicates()
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
            .eraseToAnyPublisher()
    }

    func setNetworkImageRotation(_ id: Int64, _ rotationDegrees: Int) {
        try! database.setNetworkImageRotation(id, rotationDegrees)
    }

    func setLocalImageRotation(_ id: Int64, _ rotationDegrees: Int) {
        try! database.setLocalImageRotation(id, rotationDegrees)
    }

    func upsertLocalImage(_ localImage: WorksiteLocalImageRecord) throws {
        try database.upsertLocalImage(localImage)
    }

    func upsertLocalImages(_ images: [WorksiteLocalImageRecord]) throws {
        try database.upsertLocalImages(images)
    }

    func deleteLocalImage(_ id: Int64) throws {
        try database.deleteLocalImage(id)
    }

    func deleteNetworkImage(_ id: Int64) throws {
        try database.markNetworkImageForDelete(id)
    }

    func getDeletedPhotoFileIds(_ worksiteId: Int64) throws -> [Int64] {
        try reader.read { db in
            let networkFileLocalImageAlias = TableAlias(name: "fi")
            let fi = NetworkFileRecord.networkFileLocalImage.aliased(networkFileLocalImageAlias)
            let worksiteToNetworkFileAlias = TableAlias(name: "wf")
            let wf = NetworkFileRecord.networkFileToWorksite
                .aliased(worksiteToNetworkFileAlias)
            return try NetworkFileRecord
                .all()
                .selectFileId()
                .including(optional: fi)
                .including(required: wf)
                .byWorksiteIdNotDeleted(
                    networkFileLocalImageAlias,
                    worksiteToNetworkFileAlias,
                    worksiteId
                )
                .asRequest(of: Int64.self)
                .fetchAll(db)
        }
    }

    func getWorksiteLocalImages(_ worksiteId: Int64) -> [PopulatedLocalImageDescription] {
        try! reader.read{ db in
            try WorksiteLocalImageRecord
                .all()
                .selectDescriptionColumns()
                .byWorksiteId(worksiteId)
                .asRequest(of: PopulatedLocalImageDescription.self)
                .fetchAll(db)
        }
    }

    func saveUploadedFile(
        _ worksiteId: Int64,
        _ localImage: PopulatedLocalImageDescription,
        _ networkFile: NetworkFileRecord
    ) throws {
        try database.saveUploadedFile(worksiteId, localImage, networkFile)
    }

    // TODO: Write tests
    func getUploadImageWorksiteIds() -> [PopulatedWorksiteImageCount] {
        try! reader.read{ db in
            let imageCountCte = CommonTableExpression(
                named: "imageCount",
                request: WorksiteLocalImageRecord
                    .all()
                    .getUploadImageCounts()
            )
            return try imageCountCte
                .all()
                .with(imageCountCte)
                .asRequest(of: PopulatedWorksiteImageCount.self)
                .fetchAll(db)
        }
    }

    func getPendingLocalImageFileNames() -> [String] {
        try! reader.read { db in
            try WorksiteLocalImageRecord
                .all()
                .selectFileName()
                .asRequest(of: String.self)
                .fetchAll(db)
        }
    }

    func getNewestLocalImageId() -> Int64? {
        try! reader.read { db in
            try WorksiteLocalImageRecord
                .all()
                .selectHighestId()
                .asRequest(of: Int64.self)
                .fetchOne(db)
        }
    }
}

extension AppDatabase {
    fileprivate func setNetworkImageRotation(_ id: Int64, _ rotationDegrees: Int) throws {
        try dbWriter.write { db in
            try NetworkFileLocalImageRecord(
                id: id,
                isDeleted: false,
                rotateDegrees: rotationDegrees
            )
            .insert(db, onConflict: .ignore)

            try NetworkFileLocalImageRecord.updateRotation(db, id, rotationDegrees)
        }

    }

    fileprivate func setLocalImageRotation(_ id: Int64, _ rotationDegrees: Int) throws {
        try dbWriter.write { db in
            try WorksiteLocalImageRecord.updateLocalImageRotation(db, id, rotationDegrees)
        }
    }

    fileprivate func upsertLocalImage(_ record: WorksiteLocalImageRecord) throws {
        try dbWriter.write { db in try record.insertOrUpdateTag(db) }
    }

    fileprivate func upsertLocalImages(_ records: [WorksiteLocalImageRecord]) throws {
        try dbWriter.write { db in
            for record in records {
                try record.insertOrUpdateTag(db)
            }
        }
    }

    private func deleteLocalImage(
        _ db: Database,
        _ id: Int64
    ) throws {
        _ = try WorksiteLocalImageRecord
            .filter(id: id)
            .deleteAll(db)
    }

    fileprivate func deleteLocalImage(_ id: Int64) throws {
        try dbWriter.write { db in try deleteLocalImage(db, id) }
    }

    fileprivate func markNetworkImageForDelete(_ id: Int64) throws {
        try dbWriter.write { db in try NetworkFileLocalImageRecord.markForDelete(db, id) }
    }

    fileprivate func saveUploadedFile(
        _ worksiteId: Int64,
        _ localImage: PopulatedLocalImageDescription,
        _ networkFile: NetworkFileRecord
    ) throws {
        try dbWriter.write{ db in
            try networkFile.upsert(db)
            try WorksiteToNetworkFileRecord(
                id: worksiteId,
                networkFileId: networkFile.id
            )
            .insert(db, onConflict: .ignore)
            try deleteLocalImage(db, localImage.id)
        }
    }
}
