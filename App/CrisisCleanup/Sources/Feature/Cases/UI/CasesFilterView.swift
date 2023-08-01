import SwiftUI
import SVGView

struct CasesFilterView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: CasesFilterViewModel

    var tempSections = ["Distance", "General", "Personal Info", "Flags", "Work", "Dates"]

    @State var tempVul = 100.0
    @State var tempDate = Date()
    @State var dates: Set<DateComponents> = []
    @State var datesCache: Set<DateComponents> = []
    @State var start: DateComponents?
    @State var end: DateComponents?
    @State var datesFilled = false
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

                                MultiDatePicker("Select your preferred dates", selection: $dates)

                                    .onChange(of: dates) { change in
//                                        print(change.description)
                                        if(datesFilled) {
                                            for date in dates {
                                                if !datesCache.contains(date) {
                                                    print(date)
                                                    datesFilled = false
                                                    dates = [date]
                                                    datesCache = []

                                                    break
                                                }
                                            }
                                            if(datesFilled) {
                                                print(datesFilled.description)
                                                for date in datesCache {
                                                    print("new date within range")

                                                    if(!dates.contains(date)) {
                                                        print(date)
                                                        datesFilled = false
                                                        dates = [date]
                                                        datesCache = []

                                                        break
                                                    }
                                                }
                                            }
//
                                        } else if (dates.count == 2) {
                                            print("adding to dates")
                                            var date1 = Calendar.current.date(from: DateComponents(year: 2023, month: 08, day: 15))!
                                            var date2 = Calendar.current.date(from: DateComponents(year: 2023, month: 08, day: 18))!

                                            var count = 0
                                            for comp in dates {
                                                if(count == 0) {
                                                    date1 = Calendar.current.date(from: comp)!
                                                } else {
                                                    date2 = Calendar.current.date(from: comp)!
                                                }
                                                count += 1
                                            }
                                            var fromDate = Date()
                                            var toDate = Date()
                                            if date1 < date2 {
                                                fromDate = date1
                                                toDate = date2
                                            } else {
                                                fromDate = date2
                                                toDate = date1
                                            }

                                            for date in stride(from:fromDate, to:toDate, by: TimeInterval(86400)) {
//                                                print(date)
                                                let comps = Calendar.current.dateComponents([.calendar, .era, .year, .month, .day], from: date)

                                                dates.insert(comps)
                                            }

                                            datesFilled = true
                                            datesCache = dates
                                        }
//                                        print(change.description)
//                                        print(dates.description)

                                    }
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
