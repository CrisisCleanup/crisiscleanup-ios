import Combine
import Foundation

protocol AppConfigDataSource {
    var appConfig: any Publisher<AppConfig, Never> { get }

    func setClaimThresholds(_ count: Int, _ ratio: Float)
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JsonEncoderFactory().encoder()

class AppConfigUserDefaults: AppConfigDataSource {
    let appConfig: any Publisher<AppConfig, Never>

    init() {
        appConfig = UserDefaults.standard.publisher(for: \.appConfigData)
            .map { configData in
                if let data = configData,
                   let decodedData = try? jsonDecoder.decode(AppConfig.self, from: data) {
                    return decodedData
                }
                return AppConfig()
            }
    }

    private func setConfig(_ config: AppConfig) {
        UserDefaults.standard.appConfig = config
    }

    func setClaimThresholds(_ count: Int, _ ratio: Float) {
        setConfig(UserDefaults.standard.appConfig.copy {
            $0.claimCountThreshold = count
            $0.closedClaimRatioThreshold = ratio
        })
    }
}

fileprivate let appConfigKey = "app_config"
extension UserDefaults {
    @objc dynamic fileprivate(set) var appConfigData: Data? {
        get { data(forKey: appConfigKey) }
        set { set(newValue, forKey: appConfigKey) }
    }

    var appConfig: AppConfig {
        get {
            if let data = appConfigData,
               let info = try? jsonDecoder.decode(AppConfig.self, from: data) {
                return info
            }
            return AppConfig()
        }
        set {
            if let data = try? jsonEncoder.encode(newValue) {
                appConfigData = data
            }
        }
    }
}
