import Combine
import Foundation

protocol AppMetricsDataSource {
    var metrics: any Publisher<AppMetrics, Never> { get }

    func setAppOpen(_ appBuild: Int64, _ timestamp: Date)

    func setMinSupportedVersion(_ minSupportedAppVersion: MinSupportedAppVersion)
}

extension AppMetricsDataSource {
    func setAppOpen(_ appBuild: Int64) {
        setAppOpen(appBuild, Date.now)
    }
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JsonEncoderFactory().encoder()

class LocalAppMetricsDataSource: AppMetricsDataSource {
    let metrics: any Publisher<AppMetrics, Never>

    private let updateLock = NSLock()

    init() {
        metrics = UserDefaults.standard.publisher(for: \.appMetricsData)
            .map { metricsData in
                let appMetrics: AppMetrics
                if let metricsData = metricsData,
                   let data = try? jsonDecoder.decode(AppMetrics.self, from: metricsData) {
                    appMetrics = data
                } else {
                    appMetrics = AppMetrics()
                }
                return appMetrics
            }
    }

    private func update(_ metrics: AppMetrics) {
        updateLock.withLock {
            UserDefaults.standard.appMetrics = metrics
        }
    }

    func setAppOpen(_ appBuild: Int64, _ timestamp: Date) {
        update(UserDefaults.standard.appMetrics.copy {
            $0.openBuild = appBuild
            $0.openTimestamp = timestamp
        })
    }

    func setMinSupportedVersion(_ minSupportedAppVersion: MinSupportedAppVersion) {
        update(UserDefaults.standard.appMetrics.copy {
            $0.minSupportedVersion = minSupportedAppVersion
        })
    }
}

fileprivate let appMetricsKey = "app_metrics"
extension UserDefaults {
    @objc dynamic fileprivate(set) var appMetricsData: Data? {
        get { data(forKey: appMetricsKey) }
        set { set(newValue, forKey: appMetricsKey) }
    }

    var appMetrics: AppMetrics {
        get {
            if let data = appMetricsData,
               let info = try? jsonDecoder.decode(AppMetrics.self, from: data) {
                return info
            }
            return AppMetrics()
        }
        set {
            if let data = try? jsonEncoder.encode(newValue) {
                appMetricsData = data
            }
        }
    }
}
