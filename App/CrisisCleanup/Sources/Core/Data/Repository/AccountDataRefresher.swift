import Foundation

public class AccountDataRefresher {
    private let dataSource: AccountInfoDataSource
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let organizationsRepository: OrganizationsRepository
    private let accountEventBus: AccountEventBus
    private let logger: AppLogger

    private var accountDataUpdateTime = Date.epochZero

    private let updateLock = NSLock()

    init(
        dataSource: AccountInfoDataSource,
        networkDataSource: CrisisCleanupNetworkDataSource,
        accountDataRepository: AccountDataRepository,
        organizationsRepository: OrganizationsRepository,
        accountEventBus: AccountEventBus,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.networkDataSource = networkDataSource
        self.accountDataRepository = accountDataRepository
        self.organizationsRepository = organizationsRepository
        self.accountEventBus = accountEventBus
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
        if !force,
           accountDataUpdateTime.addingTimeInterval(cacheTimeSpan) > Date.now {
            return
        }

        logger.logCapture("Syncing \(syncTag)")
        do {
            let accountData = try await dataSource.accountData.eraseToAnyPublisher().asyncFirst()
            let accountId = accountData.id
            let profile = try await networkDataSource.getProfileData(accountId)
            if profile.organization?.isActive == false {
                accountEventBus.onAccountInactiveOrganizations(accountId)
            } else if profile.hasAcceptedTerms != nil {
                updateLock.withLock {
                    dataSource.update(
                        profile.files?.profilePictureUrl,
                        profile.hasAcceptedTerms!,
                        profile.approvedIncidents!,
                        profile.activeRoles!,
                    )
                }

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
