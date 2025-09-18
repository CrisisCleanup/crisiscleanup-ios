import Combine
import Foundation

public protocol IncidentCachePreferencesDataSource {
    var preferences: any Publisher<IncidentWorksitesCachePreferences, Never> { get }

    func setPauseRegionPreferences(_ preferences: IncidentWorksitesCachePreferences)
    func setLastReconciled(_ lastReconciled: Date)
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JsonEncoderFactory().encoder()

class IncidentCachePreferencesUserDefaults: IncidentCachePreferencesDataSource {
    let preferences: any Publisher<IncidentWorksitesCachePreferences, Never>

    init() {
        preferences = UserDefaults.standard.publisher(for: \.incidentWorksitesCachePreferencesData)
            .map { preferencesData in
                if let data = preferencesData,
                   let decodedData = try? jsonDecoder.decode(IncidentWorksitesCachePreferences.self, from: data) {
                    return decodedData
                }
                return InitialIncidentWorksitesCachePreferences
            }
    }

    private func update(_ preferences: IncidentWorksitesCachePreferences) {
        UserDefaults.standard.incidentWorksitesCachePreferences = preferences
    }

    func setPauseRegionPreferences(_ preferences: IncidentWorksitesCachePreferences) {
        update(UserDefaults.standard.incidentWorksitesCachePreferences.copy {
            $0.isPaused = preferences.isPaused
            $0.isRegionBounded = preferences.isRegionBounded
            $0.boundedRegionParameters = preferences.boundedRegionParameters
        })
    }

    func setLastReconciled(_ lastReconciled: Date) {
        update(UserDefaults.standard.incidentWorksitesCachePreferences.copy {
            $0.lastReconciled = lastReconciled
        })
    }
}

fileprivate let incidentWorksitesCachePreferencesKey = "incident_worksites_cache_preferences"
extension UserDefaults {
    @objc dynamic fileprivate(set) var incidentWorksitesCachePreferencesData: Data? {
        get { data(forKey: incidentWorksitesCachePreferencesKey) }
        set { set(newValue, forKey: incidentWorksitesCachePreferencesKey) }
    }

    var incidentWorksitesCachePreferences: IncidentWorksitesCachePreferences {
        get {
            if let data = incidentWorksitesCachePreferencesData,
               let preferences = try? jsonDecoder.decode(IncidentWorksitesCachePreferences.self, from: data) {
                return preferences
            }
            return InitialIncidentWorksitesCachePreferences
        }
        set {
            if let data = try? jsonEncoder.encode(newValue) {
                incidentWorksitesCachePreferencesData = data
            }
        }
    }
}
