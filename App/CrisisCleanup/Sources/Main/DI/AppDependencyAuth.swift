extension MainComponent {
    public var accessTokenDecoder: AccessTokenDecoder { JwtDecoder() }

    public var accountUpdateRepository: AccountUpdateRepository {
        shared {
            CrisisCleanupAccountUpdateRepository(
                accountApi: accountApi,
                loggerFactory: loggerFactory
            )
        }
    }
}
