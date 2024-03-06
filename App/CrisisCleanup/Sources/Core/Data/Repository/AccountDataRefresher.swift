import Foundation

public class AccountDataRefresher {
    private let dataSource: AccountInfoDataSource
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let organizationsRepository: OrganizationsRepository
    private let logger: AppLogger

    private var accountDataUpdateTime = Date(timeIntervalSince1970: 0)

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

    private func refreshAccountData(
           _ syncTag: String,
           _ force: Bool,
           cacheTimeSpan: Double = 1.days
       ) async {
           if accountDataRepository.refreshToken.isBlank {
               return
           }
           if !force && accountDataUpdateTime.addingTimeInterval(cacheTimeSpan) > Date.now {
               return
           }

           logger.logCapture("Syncing $syncTag")
           do {
               let profile = try await networkDataSource.getProfileData()
               if profile.hasAcceptedTerms != nil {
                   dataSource.update(
                       profile.files?.profilePictureUrl,
                       profile.hasAcceptedTerms!,
                       profile.approvedIncidents!
                   )

                   accountDataUpdateTime = Date.now
               }
           } catch {
               logger.logError(error)
           }
       }

    func updateProfilePicture() async {
        await refreshAccountData("profile pic", false)
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
        await refreshAccountData("accept terms", true)
    }

    func updateApprovedIncidents(_ force: Bool = false) async {
        await refreshAccountData("approved incidents", force)
    }
}
