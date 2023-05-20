import NeedleFoundation

public protocol AppDependency: Dependency {
    var appEnv: AppEnv { get }
    var appSettingsProvider: AppSettingsProvider { get }
    var appVersionProvider: AppVersionProvider { get }
}

extension MainComponent {
    public var appVersionProvider: AppVersionProvider {
        return providesAppVersionProvider
    }

    var providesAppVersionProvider: AppVersionProvider {
        return shared { AppleAppVersionProvider() }
    }
}
