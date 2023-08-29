import Combine
import FlowStackLayout
import SwiftUI

private struct FrequencySelectView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var checkedData: ObservableBoolDictionary

    let node: FormFieldNode

    @State var tempDailyWeekly = ""
    @State var tempSelected: [String] = []
    @State var tempValue = 1
    @State var tempDate = Date()
    @State var tempSelectedRadio = ""

    var body: some View {
        VStack(alignment: .leading) {
            let isChecked = checkedData[node.fieldKey]
            HStack {
                CheckboxView(
                    checked: $checkedData[node.fieldKey],
                    text: t.t(node.formField.label)
                )
                .disabled(isChecked)

                Spacer ()
            }
            if(isChecked) {
                HStack {
                    Button {
                        tempDailyWeekly = "daily"
                    } label : {
                        let isSelected = tempDailyWeekly == "daily"
                        HStack {
                            Spacer()
                            Text("t.tDaily")
                            // TODO: Common styles
                            Spacer()
                        }
                        .padding()
                        .background( isSelected ? Color.yellow : Color.white)
                        .cornerRadius(40)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    Color.black,
                                    lineWidth: isSelected ? 0 : 1
                                )
                        )
                    }
                    .tint(.black)

                    Button {
                        tempDailyWeekly = "weekly"
                    } label : {
                        let isSelected = tempDailyWeekly == "weekly"
                        HStack {
                            Spacer()
                            Text("t.weekly")
                            // TODO: Common styles
                            Spacer()
                        }
                        .padding()
                        .background( isSelected ? Color.yellow : Color.white)
                        .cornerRadius(40)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    Color.black,
                                    lineWidth: isSelected ? 0 : 1
                                )
                        )
                    }
                    .tint(.black)

                }
                // TODO: Test
                if tempDailyWeekly == "weekly" {

                    Stepper(value: $tempValue,
                            in: 1...99,
                            step: 1) {
                        HStack {
                            Text("t.tRecur Every")
                            Text(tempValue.description)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(appTheme.colors.attentionBackgroundColor)
                                .cornerRadius(appTheme.cornerRadius)
                            Text("week(s) on:")
                        }
                    }
                    let options = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
                    FlowStack(
                        alignment: .leading,
                        horizontalSpacing: 8,
                        verticalSpacing: 8
                    ) {
                        ForEach(options, id: \.self) { option in
                            let isSelected = tempSelected.contains(option)
                            Button {
                                if isSelected {
                                    tempSelected.remove(at: tempSelected.firstIndex(of: option)!)
                                } else {
                                    tempSelected.append(option)
                                }
                            } label : {
                                Text(option)
                                // TODO: Common styles
                                    .padding()
                                    .frame(width: 75)
                                    .background( isSelected ? Color.yellow : Color.white)
                                    .cornerRadius(40)
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .strokeBorder(
                                                Color.black,
                                                lineWidth: isSelected ? 0 : 1
                                            )
                                    )
                            }
                            .tint(.black)
                        }
                    }

                    SelectEndDate(date: $tempDate)
                        .padding(.top)

                } else if tempDailyWeekly == "daily" {
                    RadioButtons(selected: $tempSelectedRadio, options: ["t.treccurringSchedule", "t.teveryWeekday"])

                    SelectEndDate(date: $tempDate)
                        .padding(.top)
                }
            }
        }
    }
}

// TODO: Reuse calendar range from Filters
private struct SelectEndDate: View {

    @Binding var date: Date
    @State var showCalendar = false
    @State var dateSelected = false

//    @State var start: Date?
//    @State var end: Date?

    var body: some View {
        HStack {
            Image(systemName: "calendar")
            Text("t.tSelect end date")
            if(dateSelected)
            {
                Text(date.formatted(.dateTime.day().month().year()))
                Image(systemName: "xmark")
                    .onTapGesture {
                        dateSelected = false
                    }
            }

        }
        .onTapGesture {
            showCalendar = true
            dateSelected = true
        }
        .sheet(isPresented: $showCalendar) {
//            CalendarSelectView(start: $start, end: $end, showCalendar: $showCalendar)
            SingleDateCalendar(date: $date, showCalendar: $showCalendar)
        }
    }
}

private struct SingleDateCalendar: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Binding var date: Date
    @Binding var showCalendar: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                let text2 = date.formatted(.dateTime.day().month().year())
                Text("t.tEnd date: " + text2)
                    .fontHeader3()
                Spacer()
                Button {
                    showCalendar = false
                } label: {
                    Text(t.t("actions.save"))
                }
            }
            .padding()
            DatePicker(
                "Start Date",
                selection: $date,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
        }
        .presentationDetents([.medium, .large])
    }
}
