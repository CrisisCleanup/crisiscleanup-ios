import Foundation

public class AccountDataRefresher {
    private let dataSource: AccountInfoDataSource
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let accountDataRepository: AccountDataRepository
    private let organizationsRepository: OrganizationsRepository
    private let incidentClaimThresholdRepository: IncidentClaimThresholdRepository
    private let accountEventBus: AccountEventBus
    private let logger: AppLogger

    private var accountDataUpdateTime = Date.epochZero
    private var incidentClaimThresholdUpdateTime = Date.epochZero

    private let updateLock = NSLock()

    init(
        dataSource: AccountInfoDataSource,
        networkDataSource: CrisisCleanupNetworkDataSource,
        accountDataRepository: AccountDataRepository,
        organizationsRepository: OrganizationsRepository,
        incidentClaimThresholdRepository: IncidentClaimThresholdRepository,
        accountEventBus: AccountEventBus,
        loggerFactory: AppLoggerFactory
    ) {
        self.dataSource = dataSource
        self.networkDataSource = networkDataSource
        self.accountDataRepository = accountDataRepository
        self.organizationsRepository = organizationsRepository
        self.incidentClaimThresholdRepository = incidentClaimThresholdRepository
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

        logger.logCapture("Refreshing \(syncTag)")
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

                if let lookup = profile.internalState?.incidentThresholdLookup {
                    let incidentThresholds = lookup.compactMap { (key: String, thresholds: NetworkIncidentClaimThreshold) in
                        if let incidentId = Int64(key),
                           let claimedCount = thresholds.claimedCount,
                           let closedRatio = thresholds.closedRatio {
                            return IncidentClaimThreshold(
                                incidentId: incidentId,
                                claimedCount: claimedCount,
                                closedRatio: closedRatio,
                            )
                        }
                        return nil
                    }
                    await incidentClaimThresholdRepository.saveIncidentClaimThresholds(accountId, incidentThresholds)
                }

                let now = Date.now
                accountDataUpdateTime = now
                incidentClaimThresholdUpdateTime = now
            }
        } catch {
            logger.logError(error)
        }
    }

    func updateProfilePicture() async {
        await refreshAccountData("profile-pic", false)
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
        await refreshAccountData("accept-terms", true)
    }

    func updateProfileIncidentsData(_ force: Bool = false) async {
        await refreshAccountData("profile-incidents-data", force)
    }

    func updateIncidentClaimThreshold() async {
        await refreshAccountData(
            "incident-claim-threshold",
            incidentClaimThresholdUpdateTime.addingTimeInterval(5.minutes) < Date.now,
        )
    }
}
