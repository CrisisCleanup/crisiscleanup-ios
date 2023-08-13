import Combine
import SwiftUI

enum AppAlertType {
    case expiredAuthTokens,
         noInternet

    var translateKey: String {
        switch self {
        case .expiredAuthTokens: return  "info.log_in_for_updates"
        case .noInternet: return  "info.no_internet"
        }
    }

    var actionKey: String {
        switch self {
        case .expiredAuthTokens: return  "actions.login"
        case .noInternet: return  ""
        }
    }
}

class AppAlertViewState: ObservableObject {
    @Published private(set) var alertType: AppAlertType?
    @Published private(set) var showAlert = false

    private var hasExpiredAuthTokens = false
    private var hasNoInternet = false
    private var hideExpiredAuthTokens = false
    private var hideNoInternet = false

    private var disposables = Set<AnyCancellable>()

    init(
        networkMonitor: NetworkMonitor,
        accountDataRepository: AccountDataRepository
    ) {
        Publishers.CombineLatest(
            networkMonitor.isNotOnline
                .eraseToAnyPublisher()
                .debounce(
                    for: .seconds(0.1),
                    scheduler: RunLoop.main
                ),
            accountDataRepository.accountData
                .eraseToAnyPublisher()
                .map { !$0.areTokensValid }
        )
            .receive(on: RunLoop.main)
            .sink(receiveValue: { isNotOnline, haxExpiredTokens in
                self.hasNoInternet = isNotOnline
                self.hasExpiredAuthTokens = haxExpiredTokens
                self.updateShowAlert()
            })
            .store(in: &disposables)
    }

    private func updateShowAlert() {
        var alertType: AppAlertType? = nil
        if hasNoInternet,
           !hideNoInternet {
            alertType = .noInternet
        }
        if alertType == nil,
           hasExpiredAuthTokens,
           !hideExpiredAuthTokens {
            alertType = .expiredAuthTokens
        }
        self.alertType = alertType

        showAlert = alertType != nil &&
        (alertType == .noInternet && !hideNoInternet) ||
        (alertType == .expiredAuthTokens && !hideExpiredAuthTokens)
    }

    func hideAlert(_ alertType: AppAlertType) {
        switch alertType {
        case .expiredAuthTokens:
            hideExpiredAuthTokens = true
        case .noInternet:
            hideNoInternet = true
        }
        updateShowAlert()
    }
}

struct AppAlertView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject private var alertViewState: AppAlertViewState

    let alertType: AppAlertType
    let action: () -> Void
    private let textKey: String
    private let actionKey: String

    init(
        _ alertType: AppAlertType,
        _ loginAction: @escaping () -> Void = {}
    ) {
        self.alertType = alertType
        action = alertType == .expiredAuthTokens ? loginAction : {}
        textKey = alertType.translateKey
        actionKey = alertType.actionKey
    }

    var body: some View {
        let text = t.t(textKey)

        HStack {
            Text(text)
                .padding(.horizontal)
                .padding(.vertical, appTheme.listItemVerticalPadding)
                .foregroundColor(.white)

            Spacer()

            if actionKey.isNotBlank {
                Button {
                    action()
                } label: {
                    Text(t.t(actionKey))
                        .padding(.vertical, appTheme.listItemVerticalPadding)
                        .fontHeader4()
                }
            }

            let buttonSize = appTheme.buttonSize
            Button {
                alertViewState.hideAlert(alertType)
            } label: {
                Image(systemName: "xmark")
            }
            .frame(minWidth: buttonSize, minHeight: buttonSize)
        }
        .cardContainer(background: appTheme.colors.navigationContainerColor)
        .tint(.white)
    }
}
