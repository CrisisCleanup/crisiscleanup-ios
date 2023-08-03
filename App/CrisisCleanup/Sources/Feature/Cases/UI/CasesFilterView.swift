import SwiftUI
import SVGView

struct CasesFilterView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: CasesFilterViewModel

    @State var svi = 100.0
    @State var daysAgo = Double(CasesFilterMaxDaysAgo)

    @State var createdStart: Date?
    @State var createdEnd: Date?

    @State var updatedStart: Date?
    @State var updatedEnd: Date?

    var body: some View {
        ScrollViewReader { proxy in
            FocusSectionSlider(
                sectionTitles: viewModel.filterSectionTitles,
                proxy: proxy
            )
            .padding(.vertical)

            VStack {
                ScrollView {
                    FilterSlidersSection(
                        svi: $svi,
                        daysAgo: $daysAgo
                    )

                    ForEach(viewModel.indexedTitles, id: \.0) { (index, sectionTitle) in
                        FormListSectionSeparator()

                        let sectionTitle = viewModel.filterSectionTitles[index]
                        VStack(alignment: .leading) {
                            FilterSectionTitle(title: sectionTitle)

                            switch index {
                            case 0:
                                FilterDistanceSection(
                                    distances: viewModel.distanceOptions
                                )
                            case 1:
                                FilterGeneralSection(
                                )
                            case 2:
                                FilterPersonalInfoSection(
                                )
                            case 3:
                                FilterFlagsSection(
                                    flags: viewModel.worksiteFlags
                                )
                            case 4:
                                FilterWorkSection(
                                    workTypes: viewModel.workTypes
                                )
                            case 5:
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
            }
        }
        .hideNavBarUnderSpace()
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct FilterSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .fontHeader3()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }
}

private struct FilterSlidersSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var svi: Double
    @Binding var daysAgo: Double

    private let minDaysAgo = Double(CasesFilterMinDaysAgo)
    private let maxDaysAgo = Double(CasesFilterMaxDaysAgo)

    var body: some View {
        VStack(alignment: .leading) {
            Text(t.t("svi.vulnerability"))

            Slider(
                value: $svi,
                in: 0...100
            )
            .tint(.black)
            HStack {
                Text(t.t("svi.most_vulnerable"))
                    .fontBodySmall()

                Spacer()

                Text(t.t("svi.everyone"))
                    .fontBodySmall()
            }
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
            .tint(.black)

            HStack {
                Text(t.t("worksiteFilters.days_ago").replacingOccurrences(of: "{days}", with: "\(CasesFilterMinDaysAgo)"))
                    .fontBodySmall()

                Spacer()

                Text(t.t("worksiteFilters.days_ago").replacingOccurrences(of: "{days}", with: "\(CasesFilterMaxDaysAgo)"))
                    .fontBodySmall()
            }
        }
        .padding(.horizontal)
    }
}

struct FilterDistanceSection: View {
    let distances: [(Double, String)]

    var body: some View {
        ForEach(distances, id: \.1) { (distance, text) in
            Text(text)
                .padding()
        }
    }
}

struct FilterGeneralSection: View {
    var body: some View {
        Text("General")
    }
}

struct FilterPersonalInfoSection: View {
    var body: some View {
        Text("Personal information")
    }
}

struct FilterFlagsSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let flags: [WorksiteFlagType]

    var body: some View {
        ForEach(flags, id: \.id) { flag in
            Text(t.t(flag.literal))
                .padding()
        }
    }
}

struct FilterWorkSection: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let workTypes: [String]

    var body: some View {
        ForEach(workTypes, id: \.self) { workTypeKey in
            let workTypeText = t.t("workType.\(workTypeKey)")
            Text(workTypeText)
                .padding()
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
            MultiDatePicker("~~Select a date range", selection: $dates)
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
                        for date in stride(from:start!, to:end!, by: TimeInterval(86400)) {
                            let comps = Calendar.current.dateComponents([.calendar, .era, .year, .month, .day], from: date)
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
