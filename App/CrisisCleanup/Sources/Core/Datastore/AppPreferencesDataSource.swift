import Combine
import Foundation

public protocol AppPreferencesDataSource {
    var preferences: any Publisher<AppPreferences, Never> { get }

    func reset()
    func setHideOnboarding(_ hide: Bool)
    func setHideGettingStartedVideo(_ hide: Bool)
    func setSyncAttempt(
        _ isSuccessful: Bool,
        _ attemptedSeconds: Double
    )
    func clearSyncData()
    func setSelectedIncident(_ id: Int64)
    func setLanguageKey(_ key: String)
    func setTableViewSortBy(_ sortBy: WorksiteSortBy)
    func setShareLocationWithOrg(_ share: Bool)
    func setNotifyDataSyncProgress(_ notify: Bool)
    func setCasesMapBounds(_ bounds: IncidentCoordinateBounds)
    func setTeamMapBounds(_ bounds: IncidentCoordinateBounds)
    func setWorkScreenView(_ isTableView: Bool)
}

extension AppPreferencesDataSource {
    func setSyncAttempt(_ isSuccessful: Bool) {
        setSyncAttempt(isSuccessful, Date().timeIntervalSince1970)
    }
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JsonEncoderFactory().encoder()

class AppPreferencesUserDefaults: AppPreferencesDataSource {
    let preferences: any Publisher<AppPreferences, Never>

    init() {
        preferences = UserDefaults.standard.publisher(for: \.appPreferencesData)
            .map { preferencesData in
                let appPreferences: AppPreferences
                if let preferencesData = preferencesData,
                   let data = try? jsonDecoder.decode(AppPreferences.self, from: preferencesData) {
                    appPreferences = data
                } else {
                    appPreferences = AppPreferences()
                }
                return appPreferences
            }
    }

    private func update(_ preferences: AppPreferences) {
        UserDefaults.standard.appPreferences = preferences
    }

    func reset() {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.hideOnboarding = false
                $0.hideGettingStartedVideo = false
                $0.selectedIncidentId = EmptyIncident.id
                $0.languageKey = "en-US"
                $0.syncAttempt = SyncAttempt()
                $0.tableViewSortBy = .none
                // TODO: Tutorial
                $0.shareLocationWithOrg = false
                $0.isWorkScreenTableView = false
            }
        )
    }

    func setHideOnboarding(_ hide: Bool) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.hideOnboarding = hide
            }
        )
    }

    func setHideGettingStartedVideo(_ hide: Bool) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.hideGettingStartedVideo = hide
            }
        )
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

    func setSelectedIncident(_ id: Int64) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.selectedIncidentId = id
            }
        )
    }

    func setLanguageKey(_ key: String) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.languageKey = key
            }
        )
    }

    func setTableViewSortBy(_ sortBy: WorksiteSortBy) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.tableViewSortBy = sortBy
            }
        )
    }

    func setShareLocationWithOrg(_ share: Bool) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.shareLocationWithOrg = share
            }
        )
    }

    func setNotifyDataSyncProgress(_ notify: Bool) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.notifyDataSyncProgress = notify
            }
        )
    }

    func setCasesMapBounds(_ bounds: IncidentCoordinateBounds) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.casesMapBounds = bounds
            }
        )
    }

    func setTeamMapBounds(_ bounds: IncidentCoordinateBounds) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.teamMapBounds = bounds
            }
        )
    }

    func setWorkScreenView(_ isTableView: Bool) {
        update(
            UserDefaults.standard.appPreferences.copy {
                $0.isWorkScreenTableView = isTableView
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
