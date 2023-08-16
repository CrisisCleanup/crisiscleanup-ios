import SwiftUI
import SVGView

struct CasesFilterView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: CasesFilterViewModel

    @State var createdStart: Date?
    @State var createdEnd: Date?

    @State var updatedStart: Date?
    @State var updatedEnd: Date?

    @State var sectionCollapse = [
        false,
        false,
        false,
        false,
        false,
        false
    ]

    var body: some View {
        ScrollViewReader { proxy in
            FocusSectionSlider(
                sectionTitles: viewModel.filterSectionTitles,
                proxy: proxy
            )
            .padding(.vertical)

            VStack {
                ScrollView {
                    FilterSlidersSection()

                    ForEach(viewModel.indexedTitles, id: \.0) { (index, sectionTitle) in
                        FormListSectionSeparator()

                        let sectionTitle = viewModel.filterSectionTitles[index]
                        VStack(alignment: .leading) {
                            FilterSectionTitle(title: sectionTitle, isCollapsed: $sectionCollapse[index])

                            switch index {
                            case 0:
                                if !sectionCollapse[0] {
                                    FilterDistanceSection(
                                        distances: viewModel.distanceOptions
                                    )
                                }
                            case 1:
                                if !sectionCollapse[1] {
                                    FilterGeneralSection()
                                }
                            case 2:
                                if !sectionCollapse[2] {
                                    FilterPersonalInfoSection()
                                }
                            case 3:
                                if !sectionCollapse[3] {
                                    FilterFlagsSection()
                                }
                            case 4:
                                if !sectionCollapse[4] {
                                    FilterWorkSection()
                                }
                            case 5:
                                if !sectionCollapse[5] {
                                    CalendarFormField(
                                        title: t.t("worksiteFilters.created"),
                                        start: $createdStart,
                                        end: $createdEnd
                                    )
                                    .padding([.horizontal, .bottom])

                                    CalendarFormField(
                                        title: t.t("worksiteFilters.updated"),
                                        start: $updatedStart,
                                        end: $updatedEnd
                                    )
                                    .padding([.horizontal, .bottom])
                                }
                            default:
                                Text("Filter section not implemented")
                            }
                        }
                        .id("section\(index)")
                        .onScrollSectionFocus(
                            proxy,
                            scrollToId: "scrollBar\(index)"
                        )
                    }
                }
                .coordinateSpace(name: "scrollForm")
                .scrollDismissesKeyboard(.immediately)

                FilterButtons()
                    .environmentObject(viewModel)
                    .listItemPadding()
            }
            .hideNavBarUnderSpace()
            .onAppear { viewModel.onViewAppear() }
            .onDisappear { viewModel.onViewDisappear() }
            .environmentObject(viewModel)
        }

        if viewModel.showExplainLocationPermssion {
            OpenAppSettingsDialog(
                title: t.t("info.allow_access_to_location"),
                dismissDialog: { viewModel.showExplainLocationPermssion = false }
            ) {
                Text(t.t("worksiteFilters.location_required_to_filter_by_distance"))
                    .padding(.horizontal)
            }
        }
    }
}

private struct FilterSectionTitle: View {
    let title: String
    @Binding var isCollapsed: Bool

    var body: some View {
        HStack {
            Button {
                isCollapsed.toggle()
            } label: {
                Text(title)
                    .fontHeader3()

                Spacer()

                Image(systemName: collapseIconName(isCollapsed))
            }
        }
        .padding()
        .tint(.black)
    }
}

private struct FilterSubsectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .fontHeader4()
            .padding(.horizontal)
    }
}

private struct FilterSliderLabelsView: View {
    let leadingLabel: String
    let trailingLabel: String

    var body: some View {
        HStack {
            Text(leadingLabel)
                .fontBodySmall()

            Spacer()

            Text(trailingLabel)
                .fontBodySmall()
        }
    }
}

private struct FilterSlidersSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesFilterViewModel

    @State var svi = 100.0
    @State var daysAgo = Double(CasesFilterMaxDaysAgo)

    private let minDaysAgo = Double(CasesFilterMinDaysAgo)
    private let maxDaysAgo = Double(CasesFilterMaxDaysAgo)

    var body: some View {
        VStack(alignment: .leading) {
            Text(t.t("svi.vulnerability"))
                .fontHeader3()

            Slider(
                value: $svi,
                in: 0...100
            )
            .onChange(of: svi) { newValue in
                let actualSvi = newValue * 0.01
                if abs(actualSvi - viewModel.casesFilters.svi) > 0.001 {
                    viewModel.changeFilters { $0.svi = actualSvi }
                }
            }
            .tint(.black)

            FilterSliderLabelsView(
                leadingLabel: t.t("svi.most_vulnerable"),
                trailingLabel: t.t("svi.everyone")
            )
        }
        .onChange(of: viewModel.casesFilters) { newValue in
            svi = newValue.svi * 100
        }
        .padding(.horizontal)

        FormListSectionSeparator()

        VStack(alignment: .leading) {
            let updatedText = t.t("worksiteFilters.updated")
            Text("\(updatedText) (\(Int(daysAgo)))")
                .fontHeader3()

            Slider(
                value: $daysAgo,
                in: minDaysAgo...maxDaysAgo,
                step: 1
            )
            .onChange(of: daysAgo) { newValue in
                if abs(newValue - Double(viewModel.casesFilters.daysAgoUpdated)) > 0.5 {
                    viewModel.changeFilters { $0.daysAgoUpdated = Int(newValue) }
                }
            }
            .tint(.black)

            FilterSliderLabelsView(
                leadingLabel: t.t("worksiteFilters.days_ago")
                    .replacingOccurrences(of: "{days}", with: "\(CasesFilterMinDaysAgo)"),
                trailingLabel: t.t("worksiteFilters.days_ago")
                    .replacingOccurrences(of: "{days}", with: "\(CasesFilterMaxDaysAgo)")
            )
        }
        .onChange(of: viewModel.casesFilters) { newValue in
            daysAgo = Double(newValue.daysAgoUpdated)
        }
        .padding(.horizontal)
    }
}

private struct FilterDistanceSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesFilterViewModel

    let distances: [(Double, String)]
    @State var selected: Double = 0.0
    @State var options: [String] = []

    var body: some View {
        if viewModel.hasInconsistentDistanceFilter {
            VStack {
                Text(t.t("~~Filtering by distance requires access to location"))

                Button {
                    _ = viewModel.requestLocationAccess()
                } label: {
                    Text(t.t("~~Grant access to location"))
                }
                .stylePrimary()
            }
            .listItemPadding()
        }

        Group {
            ForEach(distances, id: \.1) { (distance, text) in
                RadioButton(
                    text: text,
                    isSelected: distance == selected,
                    nestedLevel: 1,
                    isListItem: true
                ) {
                    if viewModel.tryChangeDistanceFilter(distance) {
                        selected = distance
                    }
                }
            }
        }
        .onChange(of: viewModel.casesFilters) { newValue in
            if abs(selected - newValue.distance) > 0.001 {
                selected = newValue.distance
            }
        }
    }
}

private struct FilterCheckboxView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesFilterViewModel

    let textKey: String
    var isNested: Bool = false
    let onUpdateValue: (CasesFilter) -> Bool
    let filterDelta: (CasesFilter, Bool) -> CasesFilter

    @State private var isChecked: Bool = false

    var body: some View {
        CheckboxView(
            checked: $isChecked,
            text: t.t(textKey),
            nestedLevel: isNested ? 1 : nil,
            isListItem: true
        )
        .onChange(of: isChecked) { newValue in
            viewModel.changeFilters(filterDelta(viewModel.casesFilters, newValue))
        }
        .onChange(of: viewModel.casesFilters) { newValue in
            isChecked = onUpdateValue(newValue)
        }
    }
}

private struct FilterSubsection<Content>: View where Content: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let titleKey: String
    let content: Content

    init(
        _ titleKey: String,
        @ViewBuilder content: () -> Content
    ) {
        self.titleKey = titleKey
        self.content = content()
    }

    var body: some View {
        FilterSubsectionTitle(title: t.t(titleKey))

        content
    }
}

private struct FilterGeneralSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesFilterViewModel

    @State private var isStatusOpen = false
    @State private var isStatusClosed = false

    private func onStatusChange(_ isOpen: Bool, _ isClosed: Bool) -> CasesFilter {
        viewModel.casesFilters.copy {
            $0.isStatusOpen = isOpen
            $0.isStatusClosed = isClosed
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            FilterSubsection("worksiteFilters.location") {
                FilterCheckboxView(
                    textKey: "worksiteFilters.in_primary_response_area",
                    isNested: true,
                    onUpdateValue: { $0.isWithinPrimaryResponseArea }
                ) { filters, isChecked in
                    filters.copy { $0.isWithinPrimaryResponseArea = isChecked }
                }

                FilterCheckboxView(
                    textKey: "worksiteFilters.in_secondary_response_area",
                    isNested: true,
                    onUpdateValue: { $0.isWithinSecondaryResponseArea }
                ) { filters, isChecked in
                    filters.copy { $0.isWithinSecondaryResponseArea = isChecked }
                }
            }

            FilterSubsection("worksiteFilters.team") {
                FilterCheckboxView(
                    textKey: "worksiteFilters.assigned_to_my_team",
                    isNested: true,
                    onUpdateValue: { $0.isAssignedToMyTeam }
                ) { filters, isChecked in
                    filters.copy { $0.isAssignedToMyTeam = isChecked }
                }
            }

            FilterSubsection("worksiteFilters.claim_reported_by") {
                FilterCheckboxView(
                    textKey: "worksiteFilters.unclaimed",
                    isNested: true,
                    onUpdateValue: { $0.isUnclaimed }
                ) { filters, isChecked in
                    filters.copy { $0.isUnclaimed = isChecked }
                }

                FilterCheckboxView(
                    textKey: "worksiteFilters.claimed_by_my_org",
                    isNested: true,
                    onUpdateValue: { $0.isClaimedByMyOrg }
                ) { filters, isChecked in
                    filters.copy { $0.isClaimedByMyOrg = isChecked }
                }

                FilterCheckboxView(
                    textKey: "worksiteFilters.reported_by_my_org",
                    isNested: true,
                    onUpdateValue: { $0.isReportedByMyOrg }
                ) { filters, isChecked in
                    filters.copy { $0.isReportedByMyOrg = isChecked }
                }
            }

            FilterSubsection("worksiteFilters.over_all_status") {
                Group {
                    CheckboxView(
                        checked: $isStatusOpen,
                        text: t.t("worksiteFilters.open"),
                        nestedLevel: 1,
                        isListItem: true
                    )
                    .onChange(of: isStatusOpen) { newValue in
                        if newValue != viewModel.casesFilters.isStatusOpen {
                            viewModel.changeFilters(onStatusChange(newValue, false))
                        }
                    }
                    CheckboxView(
                        checked: $isStatusClosed,
                        text: t.t("worksiteFilters.closed"),
                        nestedLevel: 1,
                        isListItem: true
                    )
                    .onChange(of: isStatusClosed) { newValue in
                        if newValue != viewModel.casesFilters.isStatusClosed {
                            viewModel.changeFilters(onStatusChange(false, newValue))
                        }
                    }
                }
                .onChange(of: viewModel.casesFilters) { newValue in
                    isStatusOpen = newValue.isStatusOpen
                    isStatusClosed = newValue.isStatusClosed
                }
            }

            FilterSubsection("worksiteFilters.detailed_status") {
                ForEach(viewModel.workTypeStatuses, id: \.self) { status in
                    CheckboxView(
                        checked: $viewModel.filterStatuses[status.literal],
                        text: t.t(status.literal),
                        nestedLevel: 1,
                        isListItem: true
                    )
                }
            }
        }
    }
}

private struct FilterPersonalInfoSection: View {
    var body: some View {
        FilterSubsection("worksiteFilters.my_organization") {
            FilterCheckboxView(
                textKey: "worksiteFilters.member_of_my_org",
                isNested: true,
                onUpdateValue: { $0.isMemberOfMyOrg }
            ) { filters, isChecked in
                filters.copy { $0.isMemberOfMyOrg = isChecked }
            }
        }

        FilterSubsection("worksiteFilters.personal_info") {
            FilterCheckboxView(
                textKey: "formLabels.older_than_60",
                isNested: true,
                onUpdateValue: { $0.isOlderThan60 }
            ) { filters, isChecked in
                filters.copy { $0.isOlderThan60 = isChecked }
            }

            FilterCheckboxView(
                textKey: "formLabels.children_in_home",
                isNested: true,
                onUpdateValue: { $0.hasChildrenInHome }
            ) { filters, isChecked in
                filters.copy { $0.hasChildrenInHome = isChecked }
            }

            FilterCheckboxView(
                textKey: "formLabels.first_responder",
                isNested: true,
                onUpdateValue: { $0.isFirstResponder }
            ) { filters, isChecked in
                filters.copy { $0.isFirstResponder = isChecked }
            }

            FilterCheckboxView(
                textKey: "formLabels.veteran",
                isNested: true,
                onUpdateValue: { $0.isVeteran }
            ) { filters, isChecked in
                filters.copy { $0.isVeteran = isChecked }
            }
        }
    }
}

private struct FilterFlagsSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesFilterViewModel

    var body: some View {
        ForEach(viewModel.worksiteFlags, id: \.self) { flag in
            CheckboxView(
                checked: $viewModel.filterFlags[flag.literal],
                text: t.t(flag.literal),
                nestedLevel: 1,
                isListItem: true
            )
        }
    }
}

private struct FilterWorkSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesFilterViewModel

    var body: some View {
        ForEach(viewModel.workTypes, id: \.self) { workType in
            CheckboxView(
                checked: $viewModel.filterWorkTypes[workType],
                text: t.t("workType.\(workType)"),
                nestedLevel: 1,
                isListItem: true
            )
        }
    }
}

struct CalendarFormField: View {
    var title: String
    @Binding var start: Date?
    @Binding var end: Date?
    @State var showCalendar: Bool = false

    var body: some View {
        VStack {
            HStack {
                Text(title)
                Spacer()
            }
            HStack {
                if let start = start, let end = end {
                    let text1 = start.formatted(.dateTime.day().month().year())
                    let text2 = end.formatted(.dateTime.day().month().year())
                    Text(text1 + " - " + text2)
                    Spacer()
                    Image(systemName: "xmark")
                        .padding(.trailing)
                        .onTapGesture {
                            self.start = nil
                            self.end = nil
                        }
                } else {
                    Text(" ") // Here for padding purposes
                        .hidden()
                    Spacer()
                }
                Image(systemName: "calendar")
            }
            .textFieldBorder()
            .onTapGesture {
                showCalendar.toggle()
            }
            .sheet(isPresented: $showCalendar) {
                CalendarSelectView(
                    start: $start,
                    end: $end,
                    showCalendar: $showCalendar
                )
            }
        }
    }
}

struct CalendarSelectView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @State var dates: Set<DateComponents> = []
    @State var datesCache: Set<DateComponents> = []
    @State var firstDateSelect: DateComponents = DateComponents()
    @Binding var start: Date?
    @Binding var end: Date?
    @State var datesFilled = false
    @Binding var showCalendar: Bool

    var body: some View {
        VStack(alignment:.leading) {
            let text1 = start?.formatted(.dateTime.day().month().year()) ?? t.t("worksiteFilters.start_date")
            let text2 = end?.formatted(.dateTime.day().month().year()) ?? t.t("worksiteFilters.end_date")
            HStack {
                Text("\(text1) - \(text2)")
                    .fontHeader3()
                Spacer()
                Button {
                    showCalendar = false
                } label: {
                    Text(t.t("actions.save"))
                }
                .disabled(end == nil)
            }
            .padding()
            MultiDatePicker("worksiteFilters.select_date_range", selection: $dates)
                .onAppear {
                    if let start = start, let end = end, dates.isEmpty {
                        let startComps = Calendar.current.dateComponents([.calendar, .era, .year, .month, .day], from: start)
                        dates.insert(startComps)

                        let endComps = Calendar.current.dateComponents([.calendar, .era, .year, .month, .day], from: end)
                        dates.insert(endComps)
                    }
                }
                .onChange(of: dates) { change in
                    if(datesFilled) {
                        for date in dates {
                            if !datesCache.contains(date) {
                                datesFilled = false
                                dates = [date]
                                datesCache = []
                                end = nil
                                break
                            }
                        }
                        // This determines if a date was selected in
                        // between the existing range
                        if(datesFilled) {
                            print(datesFilled.description)
                            for date in datesCache {
                                if(!dates.contains(date)) {
                                    datesFilled = false
                                    dates = [date]
                                    datesCache = []
                                    end = nil
                                    break
                                }
                            }
                        }
                    } else if (dates.count == 1) {
                        firstDateSelect = dates.first!
                        start = Calendar.current.date(from: firstDateSelect)!
                    } else if (dates.count == 2) {

                        // Determining if the second selected date
                        // is after or before the first selected
                        for comp in dates {
                            if (comp != firstDateSelect) {
                                let otherDate = Calendar.current.date(from: comp)!
                                let firstDate = Calendar.current.date(from: firstDateSelect)!
                                if otherDate > firstDate {
                                    end = otherDate
                                } else {
                                    dates = [comp]
                                    end = nil
                                    return
                                }
                            }
                        }

                        // Insert the other dates in between
                        for date in stride(
                            from: start!,
                            to:end!,
                            by: 1.days
                        ) {
                            let comps = Calendar.current.dateComponents(
                                [.calendar, .era, .year, .month, .day],
                                from: date
                            )
                            dates.insert(comps)
                        }

                        datesFilled = true
                        datesCache = dates
                    }
                }

            Spacer()
        }
        .presentationDetents([.medium, .large])
    }
}

struct FilterButtons: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var viewModel: CasesFilterViewModel

    var body: some View {
        let filters = viewModel.casesFilters
        HStack {
            let filterCount = filters.changeCount
            let noFilters = filterCount == 0
            Button {
                viewModel.clearFilters()
            } label: {
                Text(t.t("actions.clear_filters"))
            }
            .styleCancel()
            .disabled(noFilters)

            let applyFilters = t.t("actions.apply_filters")
            let applyText = noFilters ? applyFilters : "\(applyFilters) (\(filterCount))"
            Button {
                viewModel.applyFilters(filters)
                dismiss()
            } label: {
                Text(applyText)
            }
            .stylePrimary()
        }
    }
}

private func collapseIconName(_ isCollapsed: Bool) -> String {
    isCollapsed ? "chevron.up" : "chevron.down"
}
