import Combine

protocol AuthenticateViewModelProtocol: ObservableObject {
    func authenticate(_ emailAddress: String, _ password: String)
}

class AuthenticateViewModel: AuthenticateViewModelProtocol {
    let appEnv: AppEnv
    let logger: AppLogger

    init(
        appEnv: AppEnv,
        loggerFactory: AppLoggerFactory
    ) {
        self.appEnv = appEnv
        self.logger = loggerFactory.getLogger("auth")
    }

    func authenticate(_ emailAddress: String, _ password: String) {
        // TODO: validate not empty and email address is valid before attempting to authenticate
        //       Show loading, clear error, and authenticate
        //       Set error if any
    }
}
