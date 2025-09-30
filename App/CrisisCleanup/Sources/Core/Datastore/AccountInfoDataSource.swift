import Combine
import Foundation

// sourcery: AutoMockable
protocol AccountInfoDataSource {
    var accountData: any Publisher<AccountData, Never> { get }

    func setAccount(_ info: AccountInfo)
    func clearAccount()
    func updateExpiry(_ expirySeconds: Int64)
    func expireAccessToken()
    func update(
        _ pictureUrl: String?,
        _ isAcceptedTerms: Bool,
        _ incidentIds: Set<Int64>,
        _ activeRoles: Set<Int>
    )
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JsonEncoderFactory().encoder()

class AccountInfoUserDefaults: AccountInfoDataSource {
    let accountData: any Publisher<AccountData, Never>

    init() {
        accountData = UserDefaults.standard.publisher(for: \.accountInfoData)
            .map { infoData in
                let accountData: AccountData
                if infoData != nil,
                   let info = try? jsonDecoder.decode(AccountInfo.self, from: infoData!) {
                    accountData = info.asAccountData()
                } else {
                    accountData = emptyAccountData
                }
                return accountData
            }
    }

    func setAccount(_ info: AccountInfo) {
        UserDefaults.standard.accountInfo = info
    }

    func clearAccount() {
        setAccount(AccountInfo())
    }

    func updateExpiry(_ expirySeconds: Int64) {
        let info = UserDefaults.standard.accountInfo
        if info.id > 0 {
            setAccount(
                info.copy {
                    $0.expirySeconds = expirySeconds
                }
            )
        }
    }

    func expireAccessToken() {
        updateExpiry(1)
    }

    func update(
        _ pictureUrl: String?,
        _ isAcceptedTerms: Bool,
        _ incidentIds: Set<Int64>,
        _ activeRoles: Set<Int>
    ) {
        let info = UserDefaults.standard.accountInfo
        if info.id > 0 {
            setAccount(
                info.copy {
                    if let p = pictureUrl {
                        $0.profilePictureUri = p
                    }
                    $0.hasAcceptedTerms = isAcceptedTerms
                    $0.incidentIds = incidentIds
                    $0.activeRoles = activeRoles
                }
            )
        }
    }
}

fileprivate let accountInfoKey = "account_info"
extension UserDefaults {
    @objc dynamic fileprivate(set) var accountInfoData: Data? {
        get { data(forKey: accountInfoKey) }
        set { set(newValue, forKey: accountInfoKey) }
    }

    var accountInfo: AccountInfo {
        get {
            if let data = accountInfoData,
               let info = try? jsonDecoder.decode(AccountInfo.self, from: data) {
                return info
            }
            return AccountInfo()
        }
        set {
            if let data = try? jsonEncoder.encode(newValue) {
                accountInfoData = data
            }
        }
    }
}
