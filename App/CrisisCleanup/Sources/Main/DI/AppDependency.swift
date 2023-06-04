import NeedleFoundation

public protocol AppDependency: Dependency {
    var appEnv: AppEnv { get }
    var appSettingsProvider: AppSettingsProvider { get }
    var appVersionProvider: AppVersionProvider { get }
    var loggerFactory: AppLoggerFactory { get }

    var inputValidator: InputValidator { get }

    var networkRequestProvider: NetworkRequestProvider { get }
    var authApi: CrisisCleanupAuthApi { get }

    var authenticateViewBuilder: AuthenticateViewBuilder { get }

    var authEventBus: AuthEventBus { get }
    var accountDataRepository: AccountDataRepository { get }
}

extension MainComponent {
    public var appVersionProvider: AppVersionProvider { providesAppVersionProvider }

    public var inputValidator: InputValidator { shared { CommonInputValidator() } }

    var providesAppVersionProvider: AppVersionProvider { shared { AppleAppVersionProvider() } }

    public var networkRequestProvider: NetworkRequestProvider {
        shared { CrisisCleanupNetworkRequestProvider(appSettingsProvider) }
    }

    public var authApi: CrisisCleanupAuthApi {
        shared {
            AuthApiClient(
                appEnv: appEnv,
                networkRequestProvider: networkRequestProvider
            )
        }
    }

    public var authenticateViewBuilder: AuthenticateViewBuilder { self }

    public var authEventBus: AuthEventBus {
        return shared { CrisisCleanupAuthEventBus() }
    }

    public var accountDataRepository: AccountDataRepository {
        let accountDataSource = AccountInfoUserDefaults()
        let secureDataSource = KeychainDataSource()
        return shared {
            CrisisCleanupAccountDataRepository(
                accountDataSource,
                secureDataSource,
                self.authEventBus,
                self.loggerFactory
            )
        }
    }
}
