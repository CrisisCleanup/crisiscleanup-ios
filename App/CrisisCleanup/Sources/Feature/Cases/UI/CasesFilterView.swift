import SwiftUI
import SVGView

struct CasesFilterView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: CasesFilterViewModel

    var tempSections = ["Distance", "General", "Personal Info", "Flags", "Work", "Dates"]

    @State var tempVul = 100.0

    @State var createdStart: Date?
    @State var createdEnd: Date?

    @State var updatedStart: Date?
    @State var updatedEnd: Date?

    @State var updated = 0.0
    var maxUpdated = 193
    var recentUpdated = 3

    var body: some View {
        ZStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        FocusSectionSlider(
                            sectionTitles: tempSections,
                            proxy: proxy
                        )

                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Vulnerability")
                                    Spacer()
                                }
                                Slider(
                                    value: $tempVul,
                                    in: 0...100
                                )
                                .tint(.black)
                                HStack {
                                    Text("Most Vulnerable")
                                        .font(.caption)

                                    Spacer()

                                    Text("Everyone")
                                        .font(.caption)
                                }
                            }.padding(.horizontal)
                        }

                        FormListSectionSeparator()

                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Updated \(maxUpdated)")
                                    Spacer()
                                }
                                Slider(
                                    value: $updated,
                                    in: Double(recentUpdated)...Double(maxUpdated),
                                    step: 1
                                )
                                .tint(.black)

                                HStack {
                                    Text("\(recentUpdated)")
                                        .font(.caption)

                                    Spacer()

                                    Text("\(maxUpdated)")
                                        .font(.caption)
                                }
                            }.padding(.horizontal)
                        }

                        FormListSectionSeparator()

                        HStack {
                            Text("placeholder for section")
                        }

                        FormListSectionSeparator()

                        HStack {
                            VStack {
                                Text("Dates")

                                CalendarFormField(title: "t.tCreated", start: $createdStart, end: $createdEnd)
                                    .padding([.horizontal, .bottom])

                                CalendarFormField(title: "t.tUpdated", start: $updatedStart, end: $updatedEnd)
                                    .padding(.horizontal)
                            }
                        }

                        Spacer()
                    }
                    .coordinateSpace(name: "scrollForm")
                    .scrollDismissesKeyboard(.immediately)
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
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
            let text1 = start?.formatted(.dateTime.day().month().year()) ?? "t.tStart Date"
            let text2 = end?.formatted(.dateTime.day().month().year()) ?? "t.tEnd Date"
            HStack {
                Text(text1 + " - " + text2)
                    .font(.title2)
                Spacer()
                Button {
                    showCalendar = false
                } label: {
                    Text("t.tSave")
                }
                .disabled(end == nil)
            }
            .padding()
            MultiDatePicker("Select your preferred dates", selection: $dates)
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
