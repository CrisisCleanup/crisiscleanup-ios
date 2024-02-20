import Foundation

public class AccountDataRefresher {
    private let dataSource: AccountInfoDataSource
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let organizationsRepository: OrganizationsRepository
    private let logger: AppLogger

    private var profilePictureUpdateTime = Date(timeIntervalSince1970: 0)

    init(
        dataSource: AccountInfoDataSource,
        networkDataSource: CrisisCleanupNetworkDataSource,
        accountDataRepository: AccountDataRepository,
        organizationsRepository: OrganizationsRepository,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
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

    func updateAcceptedTerms() async {
        let hasAcceptedTerms = await networkDataSource.getProfileAcceptedTerms()
        dataSource.updateAcceptedTerms(hasAcceptedTerms)
    }
}
