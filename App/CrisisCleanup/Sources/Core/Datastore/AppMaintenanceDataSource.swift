import Combine
import Foundation

protocol AppMaintenanceDataSource {
    var appMaintenance: any Publisher<AppMaintenance, Never> { get }

    func setFtsRebuildVersion(_ version: Int64)
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JsonEncoderFactory().encoder()

class AppMaintenanceUserDefaults: AppMaintenanceDataSource {
    let appMaintenance: any Publisher<AppMaintenance, Never>

    init() {
        appMaintenance = UserDefaults.standard.publisher(for: \.appMaintenanceData)
            .map { maintenanceData in
                if let data = maintenanceData,
                   let decodedData = try? jsonDecoder.decode(AppMaintenance.self, from: data) {
                    return decodedData
                }
                return AppMaintenance()
            }
    }

    private func setMaintenance(_ maintenance: AppMaintenance) {
        UserDefaults.standard.appMaintenance = maintenance
    }

    func setFtsRebuildVersion(_ version: Int64) {
        setMaintenance(UserDefaults.standard.appMaintenance.copy {
            $0.ftsRebuildVersion = version
        })
    }
}

fileprivate let appMaintenanceKey = "app_maintenance"
extension UserDefaults {
    @objc dynamic fileprivate(set) var appMaintenanceData: Data? {
        get { data(forKey: appMaintenanceKey) }
        set { set(newValue, forKey: appMaintenanceKey) }
    }

    var appMaintenance: AppMaintenance {
        get {
            if let data = appMaintenanceData,
               let info = try? jsonDecoder.decode(AppMaintenance.self, from: data) {
                return info
            }
            return AppMaintenance()
        }
        set {
            if let data = try? jsonEncoder.encode(newValue) {
                appMaintenanceData = data
            }
        }
    }
}
