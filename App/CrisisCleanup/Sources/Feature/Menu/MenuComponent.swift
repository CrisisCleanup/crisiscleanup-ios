import NeedleFoundation
import SwiftUI

protocol MenuViewBuilder {
    func menuView(_ openAuthScreen: @escaping () -> Void) -> AnyView
}

class MenuComponent: Component<AppDependency>, MenuViewBuilder {
    lazy var menuViewModel: MenuViewModel = MenuViewModel(
        incidentsRepository: dependency.incidentsRepository,
        worksitesRepository: dependency.worksitesRepository,
        accountDataRepository: dependency.accountDataRepository,
        accountDataRefresher: dependency.accountDataRefresher,
        syncLogRepository: dependency.syncLogRepository,
        incidentSelector: dependency.incidentSelector,
        appVersionProvider: dependency.appVersionProvider,
        appSettingsProvider: dependency.appSettingsProvider,
        databaseVersionProvider: dependency.databaseVersionProvider,
        appPreferences: dependency.appPreferences,
        authEventBus: dependency.authEventBus,
        appEnv: dependency.appEnv,
        loggerFactory: dependency.loggerFactory
    )

    func menuView(_ openAuthScreen: @escaping () -> Void) -> AnyView {
        AnyView(
            MenuView(
                viewModel: menuViewModel,
                incidentSelectViewBuilder: dependency.incidentSelectViewBuilder,
                openAuthScreen: openAuthScreen
            )
        )
    }
}
