import Foundation
import MapKit
import SwiftUI

struct IncidentWorksitesCacheView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: IncidentWorksitesCacheViewModel

    @State private var animateIsSyncing: Bool = false
    @State private var disableScroll: Bool = false

    @State private var map = MKMapView()
    @State private var isLocationOutOfBounds = false

    @State private var contentSize = CGSizeZero
    @State private var animateMapSize = CGSize(width: 128, height: 128)

    private func updateMapSize(_ preferences: IncidentWorksitesCachePreferences) {
        let mapWidth = {
            if contentSize.width > 0 {
                let scrollWidth: CGFloat = preferences.isBoundedByCoordinates ? 72 : 0
                return contentSize.width - scrollWidth
            }
            return 128
        }()

        let minSize = min(contentSize.width, contentSize.height)
        let mapHeight = preferences.isRegionBounded ? minSize : minSize / 3

        let mapSize = CGSize(width: mapWidth, height: mapHeight)
        if mapSize != animateMapSize {
            animateMapSize = mapSize
        }
    }

    var body: some View {
        let incident = viewModel.incident

        let editingParameters = viewModel.editingPreferences

        ZStack {
            GeometryReader { geometry in
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            SyncInfoActionView(
                                incidentName: incident.shortName,
                                isSyncing: $animateIsSyncing,
                            )

                            SyncChoicesView()

                            MoveOnMapView(
                                map: $map,
                                targetCoordinates: $viewModel.mapCoordinates,
                                isPinCenterScreen: $viewModel.isPinCenterScreen,
                                isTargetOutOfBounds: $isLocationOutOfBounds,
                                mapCenterMover: viewModel.mapCenterMover,
                                isScrollEnabled: editingParameters.isBoundedByCoordinates,
                            )
                            .id("map-view")
                            .frame(maxWidth: .infinity)
                            .frame(
                                width: animateMapSize.width,
                                height: animateMapSize.height,
                                alignment: .trailing
                            )
                            .animation(.easeInOut, value: animateMapSize)
                            .disabled(!editingParameters.isRegionBounded)

                            // TODO: Radius. Enable/disable.
                            Text("Radius")
                                .id("radius-view")

                            if viewModel.showExplainLocationPermission {
                                LocationAppSettingsDialog {
                                    viewModel.showExplainLocationPermission = false
                                }
                            }
                        }
                        .onChange(of: viewModel.isSyncing) { newValue in
                            animateIsSyncing = newValue
                        }
                    }
                    .scrollDisabled(disableScroll)
                    .onChange(of: geometry.size) { newValue in
                        contentSize = newValue
                        updateMapSize(editingParameters)
                    }
                    .onChange(of: viewModel.editingPreferences) { newValue in
                        updateMapSize(newValue)
                    }
                }
            }
        }
        .navigationTitle(t.t("appCache.sync_strategy"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct SyncInfoActionView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: IncidentWorksitesCacheViewModel

    let incidentName: String
    @Binding var isSyncing: Bool

    var body: some View {
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

            if isSyncing {
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
            .disabled(viewModel.editingPreferences.isPaused)
        }
        .listItemModifier()
    }
}

private struct ViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

private struct SyncChoiceItem: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let isSelected: Bool
    let textTranslateKey: String
    let subTextTranslateKey: String
    var enabled = true
    var onSelect: () -> Void = { }

    private let radioFrameName = "radioButtonSpace"
    @State private var textOffset: CGFloat = 0

    var body: some View {
        // TODO: Center align text with button. Start align texts.
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    RadioButtonImage(isSelected: isSelected)

                    Text(t.t(textTranslateKey))
                        .background(GeometryReader {
                            let frame = $0.frame(in: .named(radioFrameName))
                            Color.clear.preference(
                                key: ViewOffsetPreferenceKey.self,
                                value: frame.origin.x
                            )
                            .onPreferenceChange(ViewOffsetPreferenceKey.self) {
                                textOffset = $0
                            }
                        })
                }

                Text(t.t(subTextTranslateKey))
                    .padding(.top, appTheme.textListVerticalPadding)
                    .padding(.leading, textOffset)
                    .fontBodyMedium()
            }
            .coordinateSpace(name: radioFrameName)
            .listItemModifier()
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct SyncChoicesView: View {
    @EnvironmentObject var viewModel: IncidentWorksitesCacheViewModel

    var body: some View {
        let editingParameters = viewModel.editingPreferences

        VStack {
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
                    viewModel.boundCachingCases(isNearMe: false, isUserAction: true)
                    // TODO: Scroll to bounded section
                }
            )
        }
    }
}
