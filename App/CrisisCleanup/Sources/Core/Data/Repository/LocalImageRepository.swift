import Atomics
import Combine

public protocol LocalImageRepository {
    var syncingWorksiteId: any Publisher<Int64, Never> { get }
    var syncingWorksiteImage: any Publisher<Int64, Never> { get }

    func streamNetworkImageUrl(_ id: Int64) -> AnyPublisher<String?, Never>
    func streamLocalImageUri(_ id: Int64) -> AnyPublisher<String?, Never>

    func getImageRotation(_ id: Int64, _ isNetworkImage: Bool) -> Int

    func setImageRotation(
        _ id: Int64,
        _ isNetworkImage: Bool,
        _ rotationDegrees: Int
    )

    func save(_ image: WorksiteLocalImage) throws

    func deleteLocalImage(_ id: Int64) throws

    func syncWorksiteMedia(_ worksiteId: Int64) async -> Int
}

class CrisisCleanupLocalImageRepository: LocalImageRepository {
    private let worksiteDao: WorksiteDao
    private let networkFileDao: NetworkFileDao
    private let localImageDao: LocalImageDao
    private let writeApi: CrisisCleanupWriteApi
    private let syncLogger: SyncLogger
    private let appLogger: AppLogger

    private let fileUploadGuard = ManagedAtomic(false)

    private let syncingWorksiteIdSubject = CurrentValueSubject<Int64, Never>(EmptyWorksite.id)
    let syncingWorksiteId: any Publisher<Int64, Never>

    private let syncingWorksiteImageSubject = CurrentValueSubject<Int64, Never>(0)
    let syncingWorksiteImage: any Publisher<Int64, Never>

    init(
        worksiteDao: WorksiteDao,
        networkFileDao: NetworkFileDao,
        localImageDao: LocalImageDao,
        writeApi: CrisisCleanupWriteApi,
        syncLogger: SyncLogger,
        loggerFactory: AppLoggerFactory
    ) {
        self.worksiteDao = worksiteDao
        self.networkFileDao = networkFileDao
        self.localImageDao = localImageDao
        self.writeApi = writeApi
        self.syncLogger = syncLogger
        appLogger = loggerFactory.getLogger("image-repository")

        syncingWorksiteId = syncingWorksiteIdSubject
        syncingWorksiteImage = syncingWorksiteImageSubject
    }

    func streamNetworkImageUrl(_ id: Int64) -> AnyPublisher<String?, Never> {
        networkFileDao.streamNetworkImageUrl(id)
    }

    func streamLocalImageUri(_ id: Int64) -> AnyPublisher<String?, Never> {
        // TODO: Do
        Just(nil)
            .eraseToAnyPublisher()
    }

    func getImageRotation(_ id: Int64, _ isNetworkImage: Bool) -> Int {
        isNetworkImage
        ? localImageDao.getNetworkFileLocalImage(id)?.rotateDegrees ?? 0
        : localImageDao.getLocalImage(id)?.rotateDegrees ?? 0
    }

    func setImageRotation(
        _ id: Int64,
        _ isNetworkImage: Bool,
        _ rotationDegrees: Int
    ) {
        if isNetworkImage {
            localImageDao.setNetworkImageRotation(id, rotationDegrees)
        } else {
            localImageDao.setLocalImageRotation(id, rotationDegrees)
        }
    }

    func save(_ image: WorksiteLocalImage) throws {
        try localImageDao.upsertLocalImage(image.asRecord())
    }

    func deleteLocalImage(_ id: Int64) throws {
        try localImageDao.deleteLocalImage(id)
    }

    func syncWorksiteMedia(_ worksiteId: Int64) async -> Int {
        // TODO: Do
        0
    }
}
