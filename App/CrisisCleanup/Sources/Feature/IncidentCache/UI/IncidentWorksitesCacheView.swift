import Foundation
import SwiftUI

struct IncidentWorksitesCacheView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: IncidentWorksitesCacheViewModel

    @State private var animateIsSyncing: Bool = false
    @State private var disableScroll: Bool = false

    var body: some View {
        let incident = viewModel.incident

        let editingParameters = viewModel.editingPreferences

        ZStack {
            GeometryReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        let incidentName = incident.shortName
                        let syncedText = if let lastSyncedText = viewModel.lastSynced {
                            t.t("appCache.synced_incident_as_of_date")
                                .replacing("{incident_name}", with: incidentName)
                                .replacing("{sync_date}", with: lastSyncedText)
                        } else { t.t("appCache.awaiting_sync_of_incident_name")
                                .replacing("{incident_name}", with: incidentName)
                        }
                        Text(syncedText)
                            .listItemPadding()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .center) {
                            let syncStageMessage = switch (viewModel.syncStage) {
                            case .start: t.t("appCache.ready_to_sync")
                            case .incidents: t.t("appCache.syncing_incidents")
                            case .worksitesBounded: t.t("appCache.syncing_cases_in_designated_area")
                            case .worksitesPreload: t.t("appCache.syncing_nearby_cases")
                            case .worksitesCore: t.t("appCache.syncing_all_cases")
                            case .worksitesAdditional: t.t("appCache.syncing_additional_case_data")
                            case .activeIncident: t.t("appCache.syncing_active_incident")
                            case .activeIncidentOrganization: t.t("appCache.syncing_organizations_in_incident")
                            case .end: t.t("appCache.sync_finished")
                            }
                            Text(syncStageMessage)

                            if animateIsSyncing {
                                ProgressView()
                                    .circularProgress()
                            }
                        }
                        .listItemPadding()
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .center) {
                            Text(t.t("appCache.choose_download_strategy"))
                            Spacer()
                            Button {
                                viewModel.resync()
                            } label: {
                                Text(t.t("actions.sync_now"))
                            }
                            .disabled(editingParameters.isPaused)
                        }
                        .listItemModifier()

                        SyncChoicesView()
                    }
                    .onChange(of: viewModel.isSyncing) { newValue in
                        animateIsSyncing = newValue
                    }
                }
                .scrollDisabled(disableScroll)
            }
        }
        .navigationTitle(t.t("appCache.sync_strategy"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct SyncChoiceItem: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let isSelected: Bool
    let textTranslateKey: String
    let subTextTranslateKey: String
    var enabled = true
    var onSelect: () -> Void = { }

    var body: some View {
        ContentRadioButton(
            isSelected,
            onSelect,
        ) {
            // TODO: Center align text with button. Start align texts.
            VStack(alignment: .leading) {
                Text(t.t(textTranslateKey))
                    .padding(.bottom, appTheme.listItemVerticalPadding)
                Text(t.t(subTextTranslateKey))
                    .fontBodyMedium()
            }
        }
        .disabled(!enabled)
        .listItemModifier()
    }
}

private struct SyncChoicesView: View {
    @EnvironmentObject var viewModel: IncidentWorksitesCacheViewModel

    var body: some View {
        let editingParameters = viewModel.editingPreferences

        SyncChoiceItem(
            isSelected: editingParameters.isAutoCache,
            textTranslateKey: "appCache.adaptive",
            subTextTranslateKey: "appCache.adaptive_description",
            onSelect: viewModel.resumeCachingCases
        )

        SyncChoiceItem(
            isSelected: editingParameters.isPaused,
            textTranslateKey: "appCache.pause",
            subTextTranslateKey: "appCache.pause_description",
            onSelect: viewModel.pauseCachingCases
        )

        SyncChoiceItem(
            isSelected: editingParameters.isBoundedNearMe,
            textTranslateKey: "appCache.near_me",
            subTextTranslateKey: "appCache.near_me_description",
            onSelect: {
                viewModel.boundCachingCases(isNearMe: true, isUserAction: true)
                // TODO: Scroll to near me section
            }
        )

        SyncChoiceItem(
            isSelected: editingParameters.isBoundedByCoordinates,
            textTranslateKey: "appCache.choose_area",
            subTextTranslateKey: "appCache.choose_area_description",
            onSelect: {
                viewModel.boundCachingCases(isNearMe: false)
                // TODO: Scroll to bounded section
            }
        )
    }
}
