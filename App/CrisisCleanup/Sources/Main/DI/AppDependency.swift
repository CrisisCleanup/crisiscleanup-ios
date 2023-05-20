import NeedleFoundation

public protocol AppVersionDependency: Dependency {
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
