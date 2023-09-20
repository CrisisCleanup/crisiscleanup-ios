import Combine
import Foundation
import XCTest
@testable import CrisisCleanup

final class RruleHumanReadableTextTest: XCTestCase {
    private let translator = RruleTranslator()

    private let untilA = Date(timeIntervalSince1970: 2639649641)
    private let untilADate = "2053 Aug 24"

    private func makeRrule(
        _ frequency: RruleFrequency = .weekly,
        _ interval: Int = 0,
        _ days: [RruleWeekDay] = [],
        until: Date? = nil
    ) -> Rrule {
        Rrule(
            frequency: frequency,
            until: until,
            interval: interval,
            byDay: days
        )
    }

    func testDailyEveryDay() {
        let actual = makeRrule(.daily).toHumanReadableText(translator)
        let expected = "Recur Every day."
        XCTAssertEqual(expected, actual)

        let actualUntil = makeRrule(
            .daily,
            until: untilA
        ).toHumanReadableText(translator)
        let expectedUntil = "Recur Every day Until \(untilADate)."
        XCTAssertEqual(expectedUntil, actualUntil)
    }

    func testDailyEveryOneDay() {
        let actual = makeRrule(.daily, 1).toHumanReadableText(translator)
        let expected = "Recur Every day."
        XCTAssertEqual(expected, actual)
    }

    func testDailyEveryNDays() {
        let actual = makeRrule(.daily, 2).toHumanReadableText(translator)
        let expected = "Recur Every 2 days."
        XCTAssertEqual(expected, actual)
    }

    func testDailyEveryMtoF() {
        let actual = makeRrule(
            .daily,
            2,
            [.sunday]
        ).toHumanReadableText(translator)
        let expected = "Recur Every weekday (M-F)."
        XCTAssertEqual(expected, actual)
    }

    func testWeeklyNoDays() {
        let actual = makeRrule(
            .weekly
        ).toHumanReadableText(translator)
        let expected = ""
        XCTAssertEqual(expected, actual)
    }

    func testWeeklyAllDays() {
        let actual = makeRrule(
            .weekly,
            2,
            [
                .monday,
                .thursday,
                .tuesday,
                .wednesday,
                .saturday,
                .sunday,
                .friday,
            ]
        ).toHumanReadableText(translator)
        let expected = "Recur Every 2 weeks Every day."
        XCTAssertEqual(expected, actual)
    }

    func testWeeklyWeekdays() {
        let actual = makeRrule(
            .weekly,
            1,
            [
                .monday,
                .thursday,
                .friday,
                .tuesday,
                .wednesday,
            ]
        ).toHumanReadableText(translator)
        let expected = "Recur Every week on weekdays (M-F)."
        XCTAssertEqual(expected, actual)
    }

    func testWeeklyCertainDays() {
        let actualA = makeRrule(
            .weekly,
            3,
            [
                .thursday,
                .friday,
                .wednesday,
            ]
        ).toHumanReadableText(translator)
        let expectedA = "Recur Every 3 weeks on Wednesday, Thursdays, and Fridays."
        XCTAssertEqual(expectedA, actualA)

        let actualB = makeRrule(
            .weekly,
            6,
            [
                .wednesday,
            ]
        ).toHumanReadableText(translator)
        let expectedB = "Recur Every 6 weeks on Wednesdays."
        XCTAssertEqual(expectedB, actualB)

        let actualC = makeRrule(
            .weekly,
            1,
            [
                .monday,
                .thursday,
                .wednesday,
                .saturday,
                .sunday,
                .friday,
            ],
            until: untilA
        ).toHumanReadableText(translator)
        let expectedC =
        "Recur Every week on Sunday, Monday, Wednesday, Thursday, Fridays, and Saturdays Until \(untilADate)."
        XCTAssertEqual(expectedC, actualC)

        let actualD = makeRrule(
            .weekly,
            6,
            [
                .wednesday,
                .sunday,
            ]
        ).toHumanReadableText(translator)
        let expectedD = "Recur Every 6 weeks on Sundays and Wednesdays."
        XCTAssertEqual(expectedD, actualD)
    }
}

fileprivate class RruleTranslator: KeyAssetTranslator {
    private var translationCountSubject = CurrentValueSubject<Int, Never>(0)
    var translationCount: any Publisher<Int, Never>

    init() {
        translationCount = translationCountSubject
    }

    func translate(_ phraseKey: String, _ fallbackAssetKey: String) -> String {
        translate(phraseKey) ?? phraseKey
    }

    func translate(_ phraseKey: String) -> String? {
        switch phraseKey {
        case "recurringSchedule.n_days_one": return "day"
        case "recurringSchedule.n_days_other": return "{value} days"
        case "recurringSchedule.weekday_mtof": return "weekday (M-F)"
        case "recurringSchedule.n_weeks_one": return " week"
        case "recurringSchedule.n_weeks_other": return "{value} weeks"
        case "recurringSchedule.every_day": return "Every day"
        case "recurringSchedule.on_weekdays": return "on weekdays (M-F)"
        case "recurringSchedule.sunday": return "Sunday"
        case "recurringSchedule.monday": return "Monday"
        case "recurringSchedule.tuesday": return "Tuesday"
        case "recurringSchedule.wednesday": return "Wednesday"
        case "recurringSchedule.thursday": return "Thursday"
        case "recurringSchedule.friday": return "Friday"
        case "recurringSchedule.saturday": return "Saturday"
        case "recurringSchedule.on_days": return "on {day}s"
        case "recurringSchedule.on_and_days_one": return "on {day1}s and {day2}s"
        case "recurringSchedule.on_and_days_other": return "on {day1}s, and {day2}s"
        case "recurringSchedule.recur_every": return "Recur Every"
        case "recurringSchedule.until_date": return "Until {date}"
        default: return nil
        }
    }

    func t(_ phraseKey: String) -> String {
        translate(phraseKey) ?? phraseKey
    }
}
