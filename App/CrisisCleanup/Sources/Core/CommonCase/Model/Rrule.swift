import Foundation

internal enum RruleFrequency: String {
    case daily
    case weekly

    var id: String { value }

    var value: String {
        switch self {
        case .daily: return "DAILY"
        case .weekly: return "WEEKLY"
        }
    }
}

private enum RruleKey: String, Identifiable {
    case freq
    case until
    case interval
    case byDay

    var id: String { keyValue }

    var keyValue: String {
        switch self {
        case .freq: return "FREQ"
        case .until: return "UNTIL"
        case .interval: return "INTERVAL"
        case .byDay: return "BYDAY"
        }
    }
}

internal enum RruleWeekDay: Hashable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

private let rruleWeekDayCoded: [RruleWeekDay: String] = [
    .sunday: "SU",
    .monday: "MO",
    .tuesday: "TU",
    .wednesday: "WE",
    .thursday: "TH",
    .friday: "FR",
    .saturday: "SA",
]

private let reverseWeekDayLookup = rruleWeekDayCoded.map { ($0.value, $0.key) }
    .associate { $0 }


struct Rrule: Equatable {
    private static let rruleDateFormatter = DateFormatter()
    private static var dateFormatter: DateFormatter {
        self.rruleDateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        return self.rruleDateFormatter
    }

    let frequency: RruleFrequency
    let until: Date?
    let interval: Int
    let byDay: [RruleWeekDay]

    private var frequencyCoded: String {
        frequency == .daily
        ? RruleFrequency.daily.value
        : RruleFrequency.weekly.value
    }

    private var untilCoded: String {
        if let until = until,
           let date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: until) {
            return Self.dateFormatter.string(from: date)
        }
        return ""
    }

    private var byDayCoded: String {
        frequency == .daily || byDay.isEmpty
        ? ""
        : byDay.map { rruleWeekDayCoded[$0] ?? "" }.combineTrimText(",")
    }

    var rruleString: String {
        let untilCoded = untilCoded
        let byDayCoded = byDayCoded
        return [
            "\(RruleKey.freq.keyValue)=\(frequencyCoded)",
            untilCoded.isBlank ? "" : "\(RruleKey.until.keyValue)=\(untilCoded)",
            interval > 0 ? "\(RruleKey.interval.keyValue)=\(interval)" : "",
            byDayCoded.isBlank ? "" : "\(RruleKey.byDay.keyValue)=\(byDayCoded)",
        ].combineTrimText(";")
    }

    static func from(_ rruleString: String) -> Rrule {
        let parts = rruleString.split(separator: ";")
            .map { String($0) }
        let partsLookup = parts
            .associate { part in
                let keyValue = part.split(separator: "=", maxSplits: 1)
                let isSplit = keyValue.count == 2
                let key = isSplit ? keyValue[0] : "invalid"
                let value = isSplit ? keyValue[1] : "invalid"
                return (String(key), String(value))
            }

        var frequency = RruleFrequency.weekly
        var until: Date? = nil
        var interval = 0
        var byDay = [RruleWeekDay]()

        if let frequencyCoded = partsLookup[RruleKey.freq.keyValue] {
            switch frequencyCoded {
            case RruleFrequency.daily.value:
                frequency = .daily
            default:
                frequency = .weekly
            }
        }

        if let untilCoded = partsLookup[RruleKey.until.keyValue],
           let untilDecoded = dateFormatter.date(from: untilCoded) {
            until = untilDecoded
        }

        if let intervalCoded = partsLookup[RruleKey.interval.keyValue],
           let intervalValue = Int(intervalCoded) {
            interval = intervalValue
        }

        if let byDayCoded = partsLookup[RruleKey.byDay.keyValue] {
            byDay = byDayCoded.split(separator: ",")
                .map { String($0) }
                .compactMap { reverseWeekDayLookup[$0] }
        }

        return Rrule(
            frequency: frequency,
            until: until,
            interval: interval,
            byDay: byDay
        )
    }

    init(
        frequency: RruleFrequency = .daily,
        until: Date? = nil,
        interval: Int = 0,
        byDay: [RruleWeekDay] = []
    ) {
        self.frequency = frequency
        self.until = until
        self.interval = interval
        self.byDay = byDay
    }

    private func profile() -> RruleProfile {
        let days = Set(byDay)
        let hasWeekDays = days.contains(.monday) &&
        days.contains(.tuesday) &&
        days.contains(.wednesday) &&
        days.contains(.thursday) &&
        days.contains(.friday)
        let isWeekdays = hasWeekDays &&
        !days.contains(.saturday) &&
        !days.contains(.sunday)
        let isEveryDay = hasWeekDays &&
        !isWeekdays &&
        days.contains(.saturday) &&
        days.contains(.sunday)
        return RruleProfile(
            isWeekdays: isWeekdays,
            isAllDays: isEveryDay
        )
    }

    func toHumanReadableText(
        _ translator: KeyAssetTranslator
    ) -> String {
        let positiveInterval = max(interval, 1)
        let frequencyPart = {
            switch frequency {
            case .daily:
                if byDay.isEmpty {
                    return positiveInterval == 1
                    ? translator.t("recurringSchedule.n_days_one")
                    : "\(positiveInterval) \(translator.t("recurringSchedule.n_days_other"))"
                }
                return translator.t("recurringSchedule.weekday_mtof")

            case .weekly:
                if !byDay.isEmpty {
                    var weekPart = positiveInterval == 1
                    ? translator.t("recurringSchedule.n_weeks_one")
                    : "\(positiveInterval) \(translator.t("recurringSchedule.n_weeks_other"))"
                    let profile = profile()
                    if profile.isAllDays {
                        let everyDay = translator.t("recurringSchedule.every_day")
                        weekPart = "\(weekPart) \(everyDay)"
                    } else if profile.isWeekdays {
                        let onWeekdays = translator.t("recurringSchedule.on_weekdays")
                        weekPart = "\(weekPart) \(onWeekdays)"
                    } else {
                        let sundayToSaturday = [
                            "recurringSchedule.sunday",
                            "recurringSchedule.monday",
                            "recurringSchedule.tuesday",
                            "recurringSchedule.wednesday",
                            "recurringSchedule.thursday",
                            "recurringSchedule.friday",
                            "recurringSchedule.saturday",
                        ].map { translator.t($0) }
                        let sortedDaysSet = Set<RruleWeekDay>(byDay)
                        let sortedDays = Array(sortedDaysSet)
                            .compactMap { weekdayOrderLookup[$0] }
                            .sorted(by: { a, b in a < b })
                            .compactMap { $0 >= 0 && $0 < sundayToSaturday.count ? sundayToSaturday[$0] : nil }
                        let onDays = {
                            if sortedDays.count == 1 {
                                let daysString = sortedDays.joined(separator: ", ")
                                return "\(translator.t("recurringSchedule.on_days")) \(daysString)"
                            } else if sortedDays.count > 1 {
                                let startDays = Array(sortedDays[0..<sortedDays.count - 1])
                                let daysString = startDays.joined(separator: ", ")
                                if startDays.count == 1 {
                                    return translator.t("recurringSchedule.on_and_days_one")
                                        .replacingOccurrences(of: "{days}", with: daysString)
                                        .replacingOccurrences(of: "{last_day}", with: sortedDays.last!)
                                } else {
                                    return translator.t("recurringSchedule.on_and_days_other")
                                        .replacingOccurrences(of: "{days}", with: daysString)
                                        .replacingOccurrences(of: "{last_day}", with: sortedDays.last!)
                                }
                            } else {
                                return ""
                            }
                        }()
                        if onDays.isNotBlank {
                            weekPart = "\(weekPart) \(onDays)"
                        }
                    }

                    return weekPart
                }
                return ""
            }
        }()

        if frequencyPart.isNotBlank {
            let every = translator.t("recurringSchedule.every")
            var untilDate: String? = nil
            if let until = until {
                let untilDateFormat = DateFormatter()
                untilDateFormat.dateFormat = "yyyy MMM d"
                untilDate = untilDateFormat.string(from: until)
            }
            let untilPart = untilDate?.isNotBlank == true
            ? "\(translator.t("recurringSchedule.until_date")) \(untilDate!)"
            : ""
            let frequencyString = [
                every,
                frequencyPart,
                untilPart,
            ].combineTrimText(" ")
            return "\(frequencyString)."
        }

        return ""
    }
}


private let weekdayOrderLookup: [RruleWeekDay: Int] = [
    .sunday: 0,
    .monday: 1,
    .tuesday: 2,
    .wednesday: 3,
    .thursday: 4,
    .friday: 5,
    .saturday: 6,
]

fileprivate struct RruleProfile {
    /**
     * M-F
     */
    let isWeekdays: Bool
    let isAllDays: Bool
}
