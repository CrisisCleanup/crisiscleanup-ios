import Combine
import NeedleFoundation
import SwiftUI

public protocol InviteTeammateViewBuilder {
    var inviteTeammateView: AnyView { get }
}

class InviteTeammateComponent: Component<AppDependency>, InviteTeammateViewBuilder {
    private var viewModel: InviteTeammateViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.inviteTeammate.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> InviteTeammateViewModel {
        if viewModel == nil {
            viewModel = InviteTeammateViewModel(
                accountDataRepository: dependency.accountDataRepository,
                organizationsRepository: dependency.organizationsRepository,
                orgVolunteerRepository: dependency.orgVolunteerRepository,
                settingsProvider: dependency.appSettingsProvider,
                inputValidator: dependency.inputValidator,
                qrCodeGenerator: dependency.qrCodeGenerator,
                translator: dependency.translator,
                loggerFactory: dependency.loggerFactory
            )
        }
        return viewModel!
    }

    var inviteTeammateView: AnyView {
        AnyView(
            InviteTeammateView(
                viewModel: getViewModel()
            )
        )
    }
}
