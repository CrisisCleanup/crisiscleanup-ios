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
                                if(!sectionCollapse[0]) {
                                    FilterDistanceSection(
                                        distances: viewModel.distanceOptions
                                    )
                                }
                            case 1:
                                if(!sectionCollapse[1]) {
                                    FilterGeneralSection()
                                    .environmentObject(viewModel)
                                    .padding(.horizontal)
                                }
                            case 2:
                                if(!sectionCollapse[2]) {
                                    FilterPersonalInfoSection()
                                    .padding(.horizontal)
                                }
                            case 3:
                                if(!sectionCollapse[3]) {
                                    FilterFlagsSection(
                                        flags: viewModel.worksiteFlags
                                    )
                                    .padding(.horizontal)
                                }
                            case 4:
                                if(!sectionCollapse[4]) {
                                    FilterWorkSection(
                                        workTypes: viewModel.workTypes
                                    )
                                    .padding(.horizontal)
                                }
                            case 5:
                                if(!sectionCollapse[5]) {
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
                    .listItemModifier()
            }
            .hideNavBarUnderSpace()
            .onAppear { viewModel.onViewAppear() }
            .onDisappear { viewModel.onViewDisappear() }
            .environmentObject(viewModel)
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

struct FilterDistanceSection: View {
    let distances: [(Double, String)]
    @State var selected: String = ""
    @State var options: [String] = []


    var body: some View {
        let options = distances.map{$0.1}
        RadioButtons(selected: $selected, options: options)
            .padding()


    }
}

struct FilterGeneralSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var viewModel: CasesFilterViewModel

    @State var selected: [String] = []
    @State var tempBool = false


    var body: some View {
        VStack(alignment: .leading) {
            Group {
                Text(t.t("worksiteFilters.location"))

                CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.in_primary_response_area"))

                CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.in_secondary_response_area"))

                Text(t.t("worksiteFilters.team"))

                CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.assigned_to_my_team"))
            }
            Group {
                Text(t.t("worksiteFilters.claim_reported_by"))

                CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.unclaimed"))

                CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.claimed_by_my_org"))

                CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.reported_by_my_org"))
            }

            Group {
                Text(t.t("worksiteFilters.over_all_status"))

                CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.open"))

                CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.closed"))
            }

            Group {
                Text(t.t("worksiteFilters.detailed_status"))

                ForEach(viewModel.workTypeStatuses, id: \.self) { status in
                    CheckboxView(checked: $tempBool, text: t.t(status.literal))
                }
            }
        }
    }
}

struct FilterPersonalInfoSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @State var tempBool = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(t.t("worksiteFilters.my_organization"))

            CheckboxView(checked: $tempBool, text: t.t("worksiteFilters.member_of_my_org"))

            Text(t.t("worksiteFilters.my_organization"))

            CheckboxView(checked: $tempBool, text: t.t("formLabels.older_than_60"))

            CheckboxView(checked: $tempBool, text: t.t("formLabels.children_in_home"))

            CheckboxView(checked: $tempBool, text: t.t("formLabels.first_responder"))

            CheckboxView(checked: $tempBool, text: t.t("formLabels.veteran"))

        }
    }
}

struct FilterFlagsSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let flags: [WorksiteFlagType]
    @State var tempBool = false

    var body: some View {
        ForEach(flags, id: \.id) { flag in
            CheckboxView(checked: $tempBool, text: t.t(flag.literal))
        }
    }
}

struct FilterWorkSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let workTypes: [String]
    @State var isChecked = false

    var body: some View {
        ForEach(workTypes, id: \.self) { workTypeKey in
            let workTypeText = t.t("workType.\(workTypeKey)")
            CheckboxView(checked: $isChecked, text: workTypeText)
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
