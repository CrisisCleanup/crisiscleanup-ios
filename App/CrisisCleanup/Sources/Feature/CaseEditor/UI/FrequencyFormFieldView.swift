import Combine
import FlowStackLayout
import SwiftUI

private let fallbackRrule = "RRULE:FREQ=WEEKLY;BYDAY=MO;INTERVAL=1;BYHOUR=11"

internal struct FrequencySelectView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var checkedData: BindingBoolDictionary
    @Binding var rruleString: String

    let node: FormFieldNode

    @State private var isFrequencyExpanded = false

    var body: some View {
        VStack(alignment: .leading) {
            let isChecked = checkedData[node.fieldKey]
            let rRuleIn = rruleString.ifBlank { fallbackRrule }
            let showFrequencyInput = isFrequencyExpanded || (rRuleIn.isNotBlank && rRuleIn != fallbackRrule)

            HStack {
                let label = t.t(node.formField.label)
                if showFrequencyInput {
                    CheckboxTextView(isChecked: true, text: label)
                        .disabled(true)
                } else {
                    CheckboxView(
                        checked: $checkedData[node.fieldKey],
                        text: label
                    )
                }

                // TODO: Show help if field defines help
            }

            if isChecked || showFrequencyInput {
                FrequencyDailyWeeklyViews(
                    node: node,
                    rrule: Rrule.from(rRuleIn)
                ) { updatedRrule in
                    rruleString = updatedRrule.rruleString
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private let rRuleWeekDays: [RruleWeekDay] = [
    .monday,
    .tuesday,
    .wednesday,
    .thursday,
    .friday,
]

private let rruleDayOptions: [RruleWeekDay] = [
    .sunday,
    .monday,
    .tuesday,
    .wednesday,
    .thursday,
    .friday,
    .saturday,
]

private let weekdayTranslationLookup: [RruleWeekDay: String] = [
    .sunday: "recurringSchedule.sun",
    .monday: "recurringSchedule.mon",
    .tuesday: "recurringSchedule.tue",
    .wednesday: "recurringSchedule.wed",
    .thursday: "recurringSchedule.thu",
    .friday: "recurringSchedule.fri",
    .saturday: "recurringSchedule.sat",
]

private struct FrequencyDailyWeeklyViews: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    // TODO: Better state management of rrule and derived (@State) properties

    private let node: FormFieldNode
    private let rrule: Rrule
    private let updateRrule: (Rrule) -> Void

    @State private var frequency: RruleFrequency
    @State private var interval: Int
    @State private var selectedDays: Set<RruleWeekDay>
    @State private var untilDate: Date?

    @State private var showIntervalPicker = false

    init(
        node: FormFieldNode,
        rrule: Rrule,
        onUpdate: @escaping (Rrule) -> Void
    ) {
        self.node = node
        self.rrule = rrule
        updateRrule = onUpdate

        _frequency = State(initialValue: rrule.frequency)
        _interval = State(initialValue: max(1, rrule.interval))
        _selectedDays = State(initialValue: Set(rrule.byDay))
        _untilDate = State(initialValue: rrule.until)
    }

    private func sortDays(_ days: Set<RruleWeekDay>) -> [RruleWeekDay] {
        var sortedDays = Array(days)
        sortedDays.sort { a, b in
            (rruleDayOptions.firstIndex(of: a) ?? -1) < (rruleDayOptions.firstIndex(of: b) ?? -1)
        }
        return sortedDays
    }

    var body: some View {
        Picker("", selection: $frequency) {
            // TODO: Update font styles
            Text(t.t("dashboard.daily"))
                .fontHeader3()
                .tag(RruleFrequency.daily)
            Text(t.t("dashboard.weekly"))
                .fontHeader3()
                .tag(RruleFrequency.weekly)
        }
        .pickerStyle(.segmented)
        .padding(.vertical, appTheme.listItemVerticalPadding)
        .onChange(of: frequency) { newValue in
            if newValue == .weekly {
                if selectedDays.isEmpty {
                    selectedDays.insert(.sunday)
                }
            } else if newValue == .daily {
                if !selectedDays.isEmpty {
                    interval = 1
                    selectedDays = Set(rRuleWeekDays)
                    showIntervalPicker = false
                }
            }

            updateRrule(rrule.copy {
                $0.frequency = newValue
                $0.interval = interval
                $0.byDay = sortDays(selectedDays)
            })
        }

        if frequency == .daily {
            let isEveryDay = selectedDays.isEmpty
            let isEveryWeekday = !isEveryDay
            VStack {
                ContentRadioButton(
                    isEveryDay,
                    {
                        if !isEveryDay {
                            selectedDays.removeAll()

                            updateRrule(rrule.copy {
                                $0.frequency = frequency
                                $0.interval = interval
                                $0.byDay = []
                            })
                        }
                    },
                    isListItem: true
                ) {
                    Text(t.t("recurringSchedule.recur_every"))
                    Button {
                        showIntervalPicker.toggle()
                    } label: {
                        Text("\(rrule.interval)")
                        // TODO: Common dimensions
                            .padding(.horizontal, 24)
                    }
                    .stylePrimary(true)
                    .disabled(isEveryWeekday)

                    Text(t.t("recurringSchedule.day_s"))
                }
                .buttonStyle(.plain)

                if showIntervalPicker {
                    RruleIntervalPicker(
                        showPicker: $showIntervalPicker,
                        interval: $interval
                    )
                    .onChange(of: interval) { newValue in
                        updateRrule(rrule.copy {
                            $0.frequency = frequency
                            $0.interval = newValue
                            $0.byDay = []
                        })
                    }
                }

                RadioButton(
                    text: t.t("recurringSchedule.every_weekday"),
                    isSelected: isEveryWeekday,
                    isListItem: true
                ) {
                    if !isEveryWeekday {
                        selectedDays = Set(rRuleWeekDays)

                        updateRrule(rrule.copy {
                            $0.frequency = frequency
                            $0.interval = 1
                            $0.byDay = rRuleWeekDays
                        })
                    }
                }
            }
        } else {
            HStack {
                Text(t.t("recurringSchedule.recur_every"))
                Button {
                    showIntervalPicker.toggle()
                } label: {
                    Text("\(rrule.interval)")
                    // TODO: Common dimensions
                        .padding(.horizontal, 24)
                }
                .stylePrimary(true)
                Text(t.t("recurringSchedule.weeks_on"))
            }
            if showIntervalPicker {
                RruleIntervalPicker(
                    showPicker: $showIntervalPicker,
                    interval: $interval
                )
                .onChange(of: interval) { newValue in
                    updateRrule(rrule.copy {
                        $0.frequency = frequency
                        $0.interval = newValue
                    })
                }
            }

            FlowStack(
                alignment: .leading,
                // TODO: Common dimensions
                horizontalSpacing: 16,
                verticalSpacing: 16
            ) {
                ForEach(rruleDayOptions, id: \.self) { option in
                    let isSelected = selectedDays.contains(option)
                    Button {
                        if isSelected {
                            if selectedDays.count > 1 {
                                selectedDays.remove(option)
                            }
                        } else {
                            selectedDays.insert(option)
                        }
                    } label : {
                        Text(t.t(weekdayTranslationLookup[option]!))
                            .styleMultiSelectChip(isSelected)
                    }
                    .tint(.black)
                }
                .onChange(of: selectedDays) { newValue in
                    updateRrule(rrule.copy {
                        $0.frequency = frequency
                        $0.byDay = sortDays(newValue)
                    })
                }
            }
        }

        SelectEndDate(
            date: $untilDate,
            dateSelected: rrule.until != nil
        )
        .padding(.vertical)
        .onChange(of: untilDate) { newValue in
            updateRrule(rrule.copy {
                $0.frequency = frequency
                $0.until = newValue
            })
        }
    }
}

private struct RruleIntervalPicker: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var showPicker: Bool

    @Binding var interval: Int

    private let intervalMax = 99

    var body: some View {
        Picker("", selection: $interval) {
            ForEach(Array(1...intervalMax), id: \.self) { value in
                Text("\(value)")
            }
        }
        .pickerStyle(.wheel)

        HStack {
            Button {
                showPicker = false
            } label : {
                Text(t.t("actions.hide"))
            }
            .styleCancel()
        }
        .padding([.horizontal, .bottom], 8)
    }
}

private let untilDateFormatter = DateFormatter().format("yyyy-MM-dd").utcTimeZone()

private struct SelectEndDate: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.isEnabled) var isEnabled


    @Binding var date: Date?

    @State var showCalendar = false
    @State var dateSelected = false

    var body: some View {
        let disabled = !isEnabled
        let color: Color = {
            var color = Color.black
            if disabled {
                color = color.disabledAlpha()
            }
            return color
        }()

        HStack {
            Image(systemName: "calendar")
                .foregroundColor(color)
            Text(t.t("recurringSchedule.select_end_date"))
            if let endDate = date {
                Text("(\(untilDateFormatter.string(from: endDate)))")
                Spacer()
                Image(systemName: "xmark")
                    .foregroundColor(color)
                    .onTapGesture {
                        date = nil
                        dateSelected = false
                    }
            }
        }
        .onTapGesture {
            showCalendar = true
            dateSelected = true
        }
        .sheet(isPresented: $showCalendar) {
            SingleDateCalendar(
                date: date ?? Date(timeIntervalSinceNow: 86400),
                showCalendar: $showCalendar
            ) { selectedDate in
                date = selectedDate
            }
        }
    }
}

private struct SingleDateCalendar: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @State var date: Date
    @Binding var showCalendar: Bool

    var onSaveDate: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                let selectText = t.t("recurringSchedule.select_end_date")
                let dateText = date.formatted(.dateTime.day().month().year())
                Text("\(selectText) \(dateText)")
                    .fontHeader3()
                Spacer()
                Button {
                    showCalendar = false
                    onSaveDate(date)
                } label: {
                    Text(t.t("actions.save"))
                }
            }
            .padding()
            DatePicker(
                "",
                selection: $date,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
        }
        .presentationDetents([.medium, .large])
    }
}
