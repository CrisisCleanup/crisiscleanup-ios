public class GenericError: Error, Equatable {
    public let message: String

    init(_ message: String) {
        self.message = message
    }

    public static func == (lhs: GenericError, rhs: GenericError) -> Bool {
        lhs.message == rhs.message
    }
}

let NoInternetConnectionError = GenericError("No internet")
