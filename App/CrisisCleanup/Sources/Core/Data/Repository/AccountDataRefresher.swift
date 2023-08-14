import Foundation

public class AccountDataRefresher {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let organizationsRepository: OrganizationsRepository
    private let logger: AppLogger

    private var profilePictureUpdateTime = Date(timeIntervalSince1970: 0)

    init(
        networkDataSource: CrisisCleanupNetworkDataSource,
        accountDataRepository: AccountDataRepository,
        organizationsRepository: OrganizationsRepository,
        loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        self.accountDataRepository = accountDataRepository
        self.organizationsRepository = organizationsRepository
        self.logger = loggerFactory.getLogger("account-data-refresher")
    }

    func updateProfilePicture() async {
        if accountDataRepository.refreshToken.isBlank ||
            profilePictureUpdateTime.addingTimeInterval(1.days) > Date.now
        {
            return
        }

        do {
            if let pictureUrl = try await networkDataSource.getProfilePic() {
                accountDataRepository.updateProfilePicture(pictureUrl)
            }
        } catch {
            logger.logError(error)
        }
    }

    func updateMyOrganization(_ force: Bool) async {
        do {
            let organizationId = try await accountDataRepository.accountData.eraseToAnyPublisher().asyncFirst().org.id
            if organizationId > 0 {
                await organizationsRepository.syncOrganization(
                    organizationId,
                    force: force,
                    updateLocations: true
                )
            }
        } catch {
            logger.logError(error)
        }
    }
}
