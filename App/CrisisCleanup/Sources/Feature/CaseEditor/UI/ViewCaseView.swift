//  Created by Anthony Aguilar on 6/30/23.

import FlowStackLayout
import MapKit
import SwiftUI

struct ViewCaseView: View {
    @ObservedObject var viewModel: ViewCaseViewModel

    var body: some View {
        ViewCaseLayoutView()
            .environmentObject(viewModel)
    }
}

private struct ViewCaseLayoutView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewLayout: ViewLayoutDescription
    @EnvironmentObject var viewModel: ViewCaseViewModel

    @State private var selectedTab = ViewCaseTab.info
    @State private var titlePressed: Bool = false

    @ObservedObject var focusableViewState = TextInputFocusableView()

    var body: some View {
        let isBusy = viewModel.isLoading || viewModel.isSaving

        ZStack {
            if viewLayout.isListDetailLayout {
                GeometryReader { proxy in
                    HStack {
                        ViewCaseSideHeader()
                            .frame(width: proxy.size.width * listDetailListFractionalWidth)

                        ZStack {
                            MainContent(
                                selectedTab: $selectedTab,
                                isOneColumnLayout: viewLayout.isOneColumnLayout,
                                isCompactLayout: viewLayout.isShort,
                                isBusy: isBusy
                            )
                        }
                        .frame(width: proxy.size.width * listDetailDetailFractionalWidth)
                    }
                }
                .frame(maxWidth: appTheme.wideContentMaxWidth, alignment: .center)
            } else {
                MainContent(
                    selectedTab: $selectedTab,
                    isOneColumnLayout: viewLayout.isOneColumnLayout,
                    isCompactLayout: viewLayout.isShort,
                    isBusy: isBusy
                )
                .frame(maxWidth: appTheme.contentMaxWidth, alignment: .center)
            }
        }
        .if (viewLayout.isOneColumnLayout) {
            $0.toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        ViewCaseHeaderText(
                            headerTitle: viewModel.headerTitle,
                            headerSubTitle: viewModel.subTitle
                        )
                        .modifier(CopyWithAnimation(pressed: $titlePressed, copy: viewModel.headerTitle))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        ViewCaseHeaderActions()
                    }
                }
            }
        }
        .if (viewLayout.isListDetailLayout) {
            $0.navigationTitle(viewModel.headerTitle)
        }
        .hideNavBarUnderSpace()
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel.editableViewState)
        .environmentObject(focusableViewState)
        .onChange(of: viewModel.isPendingTransfer) { isPendingTransfer in
            let isTransferStarted = isPendingTransfer && viewModel.transferType != .none
            if isTransferStarted {
                router.openWorkTypeTransfer()
            }
        }
        .onChange(of: selectedTab) { newValue in
            focusableViewState.focusState = nil
            UIApplication.shared.closeKeyboard()
        }
    }
}

private struct MainContent: View {
    @EnvironmentObject var viewModel: ViewCaseViewModel

    @Binding var selectedTab: ViewCaseTab

    var isOneColumnLayout = true
    var isCompactLayout = false
    var isBusy = false

    var body: some View {
        VStack {
            if isOneColumnLayout {
                ViewCaseUpdatedAtView(updatedAt: viewModel.updatedAtText, addPadding: true)
            }

            TabContentView(
                selectedTab: $selectedTab,
                tabTitles: viewModel.tabTitles,
                isCompactLayout: isCompactLayout
            )

            Spacer()

            if isOneColumnLayout {
                ViewCaseNav(isSideNav: false)
            }
        }

        if isBusy,
           selectedTab != .info {
            ProgressView()
        }

        VStack {
            HStack {
                Text(viewModel.alertMessage)
                    .foregroundColor(Color.white)
                    .padding()
            }
            .background(viewModel.alert ? appTheme.colors.navigationContainerColor : Color.clear)
            .cornerRadius(appTheme.cornerRadius)
            .animation(.easeInOut(duration: 0.25), value: viewModel.alert)
            Spacer()
        }
        .padding(.top)
    }
}

private struct TabContentView: View {
    @Binding var selectedTab: ViewCaseTab

    @EnvironmentObject var viewModel: ViewCaseViewModel

    var tabTitles: [ViewCaseTab: String]

    var isCompactLayout = false

    private let infoTabs = Array([
        ViewCaseTab.info,
        ViewCaseTab.photos,
        ViewCaseTab.notes
    ].enumerated())

    @State private var isPhotoImageOptionsOpen = false

    var body: some View {
        HStack {
            ForEach(infoTabs, id: \.offset) { (index, tab) in
                VStack {
                    HStack{
                        Spacer()
                        Text(tabTitles[tab] ?? "")
                            .fontHeader4()
                            .onTapGesture {
                                selectedTab = tab
                            }
                        Spacer()
                    }
                    Divider()
                        .frame(height: 2)
                        .background(selectedTab == tab ? Color.orange : Color.gray)
                }
            }
        }

        TabView(selection: $selectedTab) {
            ViewCaseInfo()
                .tag(ViewCaseTab.info)
            ViewCasePhotosView(
                caseMediaManager: viewModel.caseMediaManager,
                headerTitle: viewModel.headerTitle,
                isCompactLayout: isCompactLayout,
                areOptionsOpen: $isPhotoImageOptionsOpen
            )
            .tag(ViewCaseTab.photos)
            ViewCaseNotes()
                .tag(ViewCaseTab.notes)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

private struct ViewCaseInfo: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var body: some View {
        ScrollView {
            VStack {
                if let caseState = viewModel.caseData {
                    CaseIncidentView(
                        incident: caseState.incident,
                        isPendingSync: caseState.isPendingSync,
                        isSyncing: viewModel.isSyncing,
                        scheduleSync: {
                            viewModel.scheduleSync()
                        }
                    )
                    .padding()

                    if let worksiteFlags = caseState.worksite.flags,
                       worksiteFlags.isNotEmpty {
                        FlowStack(
                            alignment: .leading,
                            horizontalSpacing: 8,
                            verticalSpacing: 8
                        ) {
                            ForEach(worksiteFlags, id: \.self) { flag in
                                WorksiteFlagChip(flag) {
                                    viewModel.removeFlag(flag)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .bottom])
                    }

                    ViewCaseRowHeader(rowNum: 1, rowTitle: t.t("caseForm.property_information"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    PropertyInformationView(worksite: caseState.worksite)

                    if let workTypeProfile = viewModel.workTypeProfile {
                        InfoWorkView(profile: workTypeProfile)
                            .environment(\.translator, viewModel)
                    }
                }
            }
        }
    }
}

private struct NoteCard: View {
    let headerText: String
    let bodyText: String
    var isSurvivor = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(headerText)
                .fontBodySmall()
                .padding(.bottom, appTheme.gridItemSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
            NoteContentView(text: bodyText)
        }
        .padding()
        .cardContainer(background: isSurvivor ? appTheme.colors.survivorNoteColorNoTransparency : Color.white)
        .padding(.horizontal)
        .padding(.bottom, appTheme.listItemVerticalPadding)
    }
}

private struct ViewCaseNotes: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel
    @EnvironmentObject var focusableViewState: TextInputFocusableView
    @EnvironmentObject var editableView: EditableView

    @State private var editingNote = ""
    @State private var hideOtherNotes = false
    @State private var animateHideOtherNotes = false

    // TODO: Configure to represent when input is scrolled out of view
    @State private var isScrolledToTop = false

    // TODO: Common dimensions
    private let fabSize = 50.0

    var body: some View {
        let disabled = editableView.disabled

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    LargeTextEditor(
                        text: $editingNote,
                        placeholder: t.t("caseView.note")
                    )
                    .id("note-input")
                    .listItemModifier()
                    .disabled(disabled)

                    Button(t.t("actions.add")) {
                        let note = WorksiteNote.create().copy {
                            $0.note = editingNote
                        }
                        viewModel.saveNote(note)
                        editingNote = ""
                        hideOtherNotes = true
                    }
                    .stylePrimary()
                    .padding(.horizontal)
                    .disabled(editingNote.isBlank || disabled)

                    if viewModel.caseData?.worksite.notes.hasSurvivorNote == true {
                        SurvivorNoteLegend()
                            .padding()
                    } else {
                        Rectangle()
                            .fill(.clear)
                            .background(.clear)
                            .frame(height: 8.0)
                    }

                    let otherNotes = viewModel.otherNotes
                    if otherNotes.isNotEmpty {
                        let otherNotesLabel = t.t("caseView.other_notes")

                        Button {
                            hideOtherNotes.toggle()
                        } label: {
                            HStack {
                                Text(otherNotesLabel)

                                Spacer()

                                CollapsibleIcon(isCollapsed: hideOtherNotes)
                            }
                            .padding(.horizontal)
                        }
                        .foregroundColor(.black)

                        if !animateHideOtherNotes {
                            ForEach(otherNotes, id: \.0) { (title, content) in
                                NoteCard(headerText: title, bodyText: content)
                            }
                        }
                    }

                    if let notes = viewModel.caseData?.worksite.notes {
                        ForEach(notes, id: \.id) { note in
                            NoteCard(
                                headerText: note.createdAt.relativeTime,
                                bodyText: note.note,
                                isSurvivor: note.isSurvivor
                            )
                        }

                        // Spacer
                        Rectangle()
                            .fill(.clear)
                            .background(.clear)
                            .frame(height: fabSize)
                            .padding([.horizontal, .bottom])
                    }
                }
                .onChange(of: hideOtherNotes) { newValue in
                    withAnimation {
                        animateHideOtherNotes = newValue
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !focusableViewState.isFocused {
                    Button {
                        proxy.scrollTo("note-input", anchor: .top)
                    } label: {
                        Image(systemName: "chevron.up")
                            .frame(width: fabSize, height: fabSize)
                            .background(appTheme.colors.attentionBackgroundColor)
                            .tint(.black)
                            .clipShape(Circle())
                            .shadow(radius: appTheme.shadowRadius)
                            .padding()

                    }
                    .disabled(isScrolledToTop)
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

private struct PropertyInformationView: View {
    @EnvironmentObject var viewModel: ViewCaseViewModel
    @EnvironmentObject var router: NavigationRouter

    let worksite: Worksite

    @State private var namePressed: Bool = false
    @State private var phonePressed: Bool = false
    @State private var emailPressed: Bool = false
    @State private var addressPressed: Bool = false

    @State var map = MKMapView()

    @State private var showWrongLocationDialog = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                // TODO: Common dimensions
                let horizontalPadding = 8.0
                let verticalPadding = 4.0
                let iconSize = 36.0
                HStack {
                    Image(systemName: "person.fill")
                        .frame(width: iconSize, height: iconSize)
                    Text(worksite.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)
                .modifier(CopyWithAnimation(pressed: $namePressed, copy: worksite.name))

                let phoneText = [worksite.phone1, worksite.phone2]
                    .filter { $0?.isNotBlank == true }
                    .joined(separator: "; ")
                HStack {
                    Image(systemName: "phone.fill")
                        .frame(width: iconSize, height: iconSize)

                    // TODO: Custom link won't work with the two numbers combined into one text
                    Text(phoneText)
                        .customLink(urlString: "tel:\(phoneText)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)
                .modifier(CopyWithAnimation(pressed: $phonePressed, copy: phoneText))

                if worksite.email?.isNotBlank == true {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .frame(width: iconSize, height: iconSize)
                        Text(worksite.email!)
                            .customLink(urlString: "mailto:\(worksite.email!)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .horizontalVerticalPadding(horizontalPadding, verticalPadding)
                    .modifier(CopyWithAnimation(pressed: $emailPressed, copy: worksite.email!))
                }

                let (addressText, addressMapItem) = worksite.addressQuery
                HStack {
                    Image(systemName: "mappin")
                        .frame(width: iconSize, height: iconSize)

                    Button {
                        addressMapItem.openInMaps()
                    } label : {
                        Text(addressText)
                            .underline()
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if worksite.hasWrongLocationFlag {
                        ExplainWrongLocationDialog(showDialog: $showWrongLocationDialog)
                    }
                }
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)
                .modifier(CopyWithAnimation(pressed: $addressPressed, copy: addressText))

                HStack {
                    Image("ic_jump_to_case_on_map", bundle: .module)
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: iconSize, height: iconSize)

                    let distanceAwayText = viewModel.distanceAway
                    if distanceAwayText.isNotBlank {
                        Text(distanceAwayText)
                    }
                }
                .onTapGesture {
                    viewModel.setEditedLocation()
                    router.returnToWork()
                }
                .horizontalVerticalPadding(horizontalPadding, verticalPadding)

                ViewCaseMapView(
                    map: $map,
                    caseCoordinates: CLLocationCoordinate2D(
                        latitude: worksite.latitude,
                        longitude: worksite.longitude
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: appTheme.listItemMapHeight)
            }
            .cardContainerPadded()
        }
    }
}
