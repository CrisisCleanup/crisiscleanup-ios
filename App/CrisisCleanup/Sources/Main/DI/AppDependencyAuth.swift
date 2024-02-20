extension MainComponent {
    public var accessTokenDecoder: AccessTokenDecoder { JwtDecoder() }

    public var accountUpdateRepository: AccountUpdateRepository {
        shared {
            CrisisCleanupAccountUpdateRepository(
                accountDataRepository: accountDataRepository,
                accountApi: accountApi,
                loggerFactory: loggerFactory
            )
        }
    }
}
