import Combine
import NeedleFoundation
import SwiftUI

public protocol CaseMoveOnMapViewBuilder {
    var caseMoveOnMapView: AnyView { get }
}

class CaseMoveOnMapComponent: Component<AppDependency>, CaseMoveOnMapViewBuilder {
    private var viewModel: CaseChangeLocationAddressViewModel? = nil

    private var disposables = Set<AnyCancellable>()

    init(
        parent: Scope,
        routerObserver: RouterObserver
    ) {
        super.init(parent: parent)

        routerObserver.pathIds
            .sink { pathIds in
                if !pathIds.contains(NavigationRoute.caseMoveOnMap.id) {
                    self.viewModel = nil
                }
            }
            .store(in: &disposables)
    }

    deinit {
        _ = cancelSubscriptions(disposables)
    }

    private func getViewModel() -> CaseChangeLocationAddressViewModel {
        if viewModel == nil {
            viewModel = CaseChangeLocationAddressViewModel(
                worksiteProvider: dependency.editableWorksiteProvider,
                locationManager: dependency.locationManager,
                incidentBoundsProvider: dependency.incidentBoundsProvider,
                searchWorksitesRepository: dependency.searchWorksitesRepository,
                addressSearchRepository: dependency.addressSearchRepository,
                appPreferences: dependency.appPreferences,
                caseIconProvider: dependency.mapCaseIconProvider,
                existingWorksiteSelector: dependency.existingWorksiteSelector,
                networkMonitor: dependency.networkMonitor,
                translator: dependency.languageTranslationsRepository,
                loggerFactory: dependency.loggerFactory
            )
        }
        return viewModel!
    }

    var caseMoveOnMapView: AnyView {
        AnyView(
            CaseMoveOnMapView(
                viewModel: getViewModel()
            )
        )
    }
}
