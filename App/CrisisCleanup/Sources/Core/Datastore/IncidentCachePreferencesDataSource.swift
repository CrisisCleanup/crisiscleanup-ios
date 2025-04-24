import Combine
import Foundation

public protocol IncidentCachePreferencesDataSource {
    var preferences: any Publisher<IncidentWorksitesCachePreferences, Never> { get }

    func setPreferences(_ preferences: IncidentWorksitesCachePreferences)
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JsonEncoderFactory().encoder()

class IncidentCachePreferencesUserDefaults: IncidentCachePreferencesDataSource {
    let preferences: any Publisher<IncidentWorksitesCachePreferences, Never>

    init() {
        preferences = UserDefaults.standard.publisher(for: \.incidentWorksitesCachePreferencesData)
            .map { preferencesData in
                let cachePreferences: IncidentWorksitesCachePreferences
                if let preferencesData = preferencesData,
                   let data = try? jsonDecoder.decode(IncidentWorksitesCachePreferences.self, from: preferencesData) {
                    cachePreferences = data
                } else {
                    cachePreferences = InitialIncidentWorksitesCachePreferences
                }
                return cachePreferences
            }
    }

    func setPreferences(_ preferences: IncidentWorksitesCachePreferences) {
        UserDefaults.standard.incidentWorksitesCachePreferences = preferences
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
