import Combine
import Foundation

protocol AppMetricsDataSource {
    var metrics: any Publisher<AppMetrics, Never> { get }

    func setAppOpen(_ appBuild: Int64, _ timestamp: Date)

    func setAppVersions(
        _ supportedAppVersion: MinSupportedAppVersion,
        _ publishedVersion: Int64,
    )
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

    init() {
        metrics = UserDefaults.standard.publisher(for: \.appMetricsData)
            .map { metricsData in
                if let data = metricsData,
                   let decodedData = try? jsonDecoder.decode(AppMetrics.self, from: data) {
                    return decodedData
                }
                return AppMetrics()
            }
    }

    private func update(_ metrics: AppMetrics) {
        UserDefaults.standard.appMetrics = metrics
    }

    func setAppOpen(_ appBuild: Int64, _ timestamp: Date) {
        update(UserDefaults.standard.appMetrics.copy {
            $0.openBuild = appBuild
            $0.openTimestamp = timestamp
            $0.installBuild = $0.installBuild <= 0 ? appBuild : $0.installBuild
        })
    }

    func setAppVersions(
        _ supportedAppVersion: MinSupportedAppVersion,
        _ publishedVersion: Int64,
    ) {
        update(UserDefaults.standard.appMetrics.copy {
            $0.minSupportedVersion = supportedAppVersion
            $0.publishedBuild = publishedVersion
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
