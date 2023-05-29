import NeedleFoundation

public protocol AuthenticationDependency: Dependency {
    var accessTokenDecoder: AccessTokenDecoder { get }
}

extension AuthenticateComponent {
    public var accessTokenDecoder: AccessTokenDecoder { providesAccessTokenDecoder }

    var providesAccessTokenDecoder: AccessTokenDecoder { JwtDecoder() }
}
