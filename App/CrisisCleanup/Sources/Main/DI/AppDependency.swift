import NeedleFoundation

public protocol AppDependency: Dependency {
    var appEnv: AppEnv { get }
    var appSettingsProvider: AppSettingsProvider { get }
    var appVersionProvider: AppVersionProvider { get }
    var loggerFactory: AppLoggerFactory { get }
}

extension MainComponent {
    public var appVersionProvider: AppVersionProvider { providesAppVersionProvider }

    var providesAppVersionProvider: AppVersionProvider { shared { AppleAppVersionProvider() } }
}
