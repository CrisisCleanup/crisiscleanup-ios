import Foundation
import MapKit
import SwiftUI

struct IncidentWorksitesCacheView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: IncidentWorksitesCacheViewModel

    @State private var animateIsSyncing: Bool = false

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
        let mapHeight = preferences.isRegionBounded ? minSize : appTheme.listItemMapHeight

        let mapSize = CGSize(width: mapWidth, height: mapHeight)
        if mapSize != animateMapSize {
            animateMapSize = mapSize
        }
    }

    var body: some View {
        let cachePreferences = viewModel.editingPreferences

        ZStack {
            GeometryReader { geometry in
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            IncidentWorksitesCacheContentView(
                                scrollView: scrollView,
                                animateIsSyncing: $animateIsSyncing,
                                mapSize: animateMapSize,
                                cachePreferences: cachePreferences,
                            )
                        }
                        .onChange(of: viewModel.isSyncing) { newValue in
                            animateIsSyncing = newValue
                        }
                    }
                    .onChange(of: geometry.size) { newValue in
                        contentSize = newValue
                        updateMapSize(cachePreferences)
                    }
                    .onChange(of: cachePreferences) { newValue in
                        updateMapSize(newValue)
                    }
                }
            }

            if viewModel.showExplainLocationPermission {
                LocationAppSettingsDialog {
                    viewModel.showExplainLocationPermission = false
                }
            }
        }
        .navigationTitle(t.t("appCache.sync_strategy"))
        .hideNavBarUnderSpace()
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct IncidentWorksitesCacheContentView: View {
    @EnvironmentObject var viewModel: IncidentWorksitesCacheViewModel

    let scrollView: ScrollViewProxy

    @Binding var animateIsSyncing: Bool

    var mapSize: CGSize

    let cachePreferences: IncidentWorksitesCachePreferences

    @State private var map = MKMapView()

    // TODO: Set initially through preferences
    @State private var boundingRadius = 1.0

    var body: some View {
        let incident = viewModel.incident

        SyncInfoActionView(
            incidentName: incident.shortName,
            isSyncing: $animateIsSyncing,
        )

        // TODO: Scroll does not take on first select
        //       Due to animating map view?
        let scrollToRadiusSection = {
            withAnimation {
                scrollView.scrollTo("radius-section", anchor: .bottom)
            }
        }
        SyncChoicesView(
            scrollToNearMeSection: scrollToRadiusSection,
            scrollToBoundedSection: scrollToRadiusSection,
        )

        CircleBoundMoveMapView(
            map: $map,
            regionChangeListener: viewModel.mapCenterMover,
            isScrollEnabled: viewModel.editingPreferences.isBoundedByCoordinates,
            targetCoordinates: viewModel.mapCoordinates,
            isPinCenterScreen: viewModel.isPinCenterScreen,
            boundingRadius: boundingRadius,
        )
        .id("map-view-section")
        .frame(maxWidth: .infinity)
        .frame(
            width: mapSize.width,
            height: mapSize.height,
            alignment: .trailing
        )
        .animation(.easeInOut, value: mapSize)
        .disabled(!cachePreferences.isRegionBounded)
        .overlay(content: {
            if !cachePreferences.isRegionBounded {
                Color.black.disabledAlpha()
            }
        })

        BoundingRadiusView(
            boundingRadius: $boundingRadius,
        )
        .id("radius-section")
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

        HStack(alignment: .center, spacing: appTheme.gridItemSpacing) {
            let syncStageMessage = switch (viewModel.syncStage) {
            case .inactive: t.t("appCache.ready_to_sync")
            case .start: t.t("appCache.starting_sync")
            case .incidents: t.t("appCache.syncing_incidents")
            case .worksitesBounded: t.t("appCache.syncing_cases_in_designated_area")
            case .worksitesPreload: t.t("appCache.syncing_nearby_cases")
            case .worksitesCore: t.t("appCache.syncing_all_cases")
            case .worksitesAdditional: t.t("appCache.syncing_additional_case_data")
            case .activeIncident: t.t("appCache.syncing_active_incident")
            case .activeIncidentOrganization: t.t("appCache.syncing_organizations_in_incident")
            case .worksitesChangeIncident: t.t("~~Syncing Cases with changed Incidents...")
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

    let scrollToNearMeSection: () -> Void
    let scrollToBoundedSection: () -> Void

    var body: some View {
        let cachePreferences = viewModel.editingPreferences

        VStack {
            SyncChoiceItem(
                isSelected: cachePreferences.isAutoCache,
                textTranslateKey: "appCache.adaptive",
                subTextTranslateKey: "appCache.adaptive_description",
                onSelect: viewModel.resumeCachingCases
            )

            SyncChoiceItem(
                isSelected: cachePreferences.isPaused,
                textTranslateKey: "appCache.pause",
                subTextTranslateKey: "appCache.pause_description",
                onSelect: viewModel.pauseCachingCases
            )

            SyncChoiceItem(
                isSelected: cachePreferences.isBoundedNearMe,
                textTranslateKey: "appCache.near_me",
                subTextTranslateKey: "appCache.near_me_description",
                onSelect: {
                    viewModel.boundCachingCases(isNearMe: true, isUserAction: true)
                    scrollToNearMeSection()
                }
            )

            SyncChoiceItem(
                isSelected: cachePreferences.isBoundedByCoordinates,
                textTranslateKey: "appCache.choose_area",
                subTextTranslateKey: "appCache.choose_area_description",
                onSelect: {
                    viewModel.boundCachingCases(isNearMe: false, isUserAction: true)
                    scrollToBoundedSection()
                }
            )
        }
    }
}

private struct BoundingRadiusView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: IncidentWorksitesCacheViewModel

    @Binding var boundingRadius: Double

    var body: some View {
        let cachePreferences = viewModel.editingPreferences

        HStack(alignment: .center) {
            let fixedRadius = String(format: "%.1f", cachePreferences.boundedRegionParameters.regionRadiusMiles)
            let radiusText = t.t("appCache.radius")
                .replacingOccurrences(of: "{magnitude}", with: fixedRadius)
            Text(radiusText)

            Spacer()

            Slider(
                value: $boundingRadius,
                in: 1...120,
            )
        }
        .disabled(!cachePreferences.isRegionBounded)
        .listItemModifier()
        .onChange(of: cachePreferences) { newValue in
            boundingRadius = newValue.isRegionBounded ? newValue.boundedRegionParameters.regionRadiusMiles : 0.0
        }
        .onChange(of: boundingRadius) { newValue in
            if newValue != cachePreferences.boundedRegionParameters.regionRadiusMiles {
                viewModel.setBoundedRegionRadius(newValue)
            }
        }
    }
}
