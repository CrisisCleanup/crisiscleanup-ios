import Foundation

enum RruleFrequency: String {
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

enum RruleWeekDay: Hashable {
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

private let rruleDateFormatter = ISO8601DateFormatter()

struct Rrule: Equatable {
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
            return rruleDateFormatter.string(from: date)
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

        var frequency = RruleFrequency.daily
        var until: Date? = nil
        var interval = 0
        var byDay = [RruleWeekDay]()

        if let frequencyCoded = partsLookup[RruleKey.freq.keyValue] {
            switch frequencyCoded {
            case RruleFrequency.weekly.value:
                frequency = .weekly
            default:
                frequency = .daily
            }
        }

        if let untilCoded = partsLookup[RruleKey.until.keyValue],
           let untilDecoded = rruleDateFormatter.date(from: untilCoded) {
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

    //    init(from decoder: Decoder) throws {
    //        var rrule = Rrule()
    //        let container = try decoder.singleValueContainer()
    //        if let value = try? container.decode(String.self) {
    //            rrule = Rrule.from(value)
    //        }
    //
    //        frequency = rrule.frequency
    //        until = rrule.until
    //        interval = rrule.interval
    //        byDay = rrule.byDay
    //    }
    //
    //    func encode(to encoder: Encoder) throws {
    //        var container = encoder.singleValueContainer()
    //        try container.encode(rruleString)
    //    }
}
