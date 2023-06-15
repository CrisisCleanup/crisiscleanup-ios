import Combine
import Foundation

public protocol AppPreferencesDataStore {
    var preferences: Published<AppPreferences>.Publisher { get }

    func setSyncAttempt(
        _ isSuccessful: Bool,
        _ attemptedSeconds: Double
    )
    func clearSyncData()
    func setSelectedIncident(id: Int64)
    func setLanguageKey(key: String)
}

extension AppPreferencesDataStore {
    func setSyncAttempt(_ isSuccessful: Bool) {
        setSyncAttempt(isSuccessful, Date().timeIntervalSince1970)
    }
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JSONEncoder()

class AppPreferencesUserDefaults: AppPreferencesDataStore {
    @Published private var preferencesStream = AppPreferences()
    lazy var preferences = $preferencesStream

    private func update(_ preferences: AppPreferences) {
        UserDefaults.standard.appPreferences = preferences
    }

    func setSyncAttempt(
        _ isSuccessful: Bool,
        _ attemptedSeconds: Double
    ) {
        let preferences = UserDefaults.standard.appPreferences
        let previousAttempt = preferences.syncAttempt
        let successfulSeconds = isSuccessful ? attemptedSeconds : previousAttempt.successfulSeconds
        let attemptedCounter = isSuccessful ? 0 : previousAttempt.attemptedCounter + 1
        let attempt = SyncAttempt(
            successfulSeconds: successfulSeconds,
            attemptedSeconds: attemptedSeconds,
            attemptedCounter: attemptedCounter
        )
        update(
            preferences.copy { $0.syncAttempt = attempt }
        )
    }

    func clearSyncData() {
        update(UserDefaults.standard.appPreferences.copy {
            $0.syncAttempt = SyncAttempt()
        })
    }

    func setSelectedIncident(id: Int64) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.selectedIncidentId = id
            }
        )
    }

    func setLanguageKey(key: String) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.languageKey = key
            }
        )
    }
}

fileprivate let appPreferencesKey = "app_preferences"
extension UserDefaults {
    @objc dynamic fileprivate(set) var appPreferencesData: Data? {
        get { data(forKey: appPreferencesKey) }
        set { set(newValue, forKey: appPreferencesKey) }
    }

    var appPreferences: AppPreferences {
        get {
            if let data = appPreferencesData,
               let preferences = try? jsonDecoder.decode(AppPreferences.self, from: data) {
                return preferences
            }
            return AppPreferences()
        }
        set {
            if let data = try? jsonEncoder.encode(newValue) {
                appPreferencesData = data
            }
        }
    }
}
