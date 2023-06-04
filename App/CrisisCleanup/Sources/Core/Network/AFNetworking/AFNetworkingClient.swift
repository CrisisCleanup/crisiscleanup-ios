import Alamofire
import Foundation

class AFNetworkingClient {
    private let appEnv: AppEnv
    private let session: Session

    init(
        _ appEnv: AppEnv,
        interceptor: RequestInterceptor? = nil
    ) {
        self.appEnv = appEnv

        let configuration = with(URLSessionConfiguration.af.default) { s in
            s.timeoutIntervalForRequest = 60
            s.timeoutIntervalForResource = 60
        }

        var eventMonitors: [EventMonitor] = []
        if appEnv.isDebuggable {
            eventMonitors.append(NetworkEventMonitor())
        }

        session = Session(
            configuration: configuration,
            interceptor: interceptor,
            eventMonitors: eventMonitors
        )
    }

    func request(_ convertible: URLRequestConvertible) -> DataRequest {
        return session.request(convertible)
    }
}

class NetworkEventMonitor : EventMonitor {
    let queue = DispatchQueue(label: "com.crisiscleanup.network")

    func requestDidFinish(_ request: Request) {
        if let headers = request.response?.headers {
            print(headers)
        }
        print(request.description)
    }

    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
//        guard let data = response.data else {
//            return
//        }
//
//         if let json = try? JSONSerialization.jsonObject(with: data) {
//             print(json)
//         }
    }
}
