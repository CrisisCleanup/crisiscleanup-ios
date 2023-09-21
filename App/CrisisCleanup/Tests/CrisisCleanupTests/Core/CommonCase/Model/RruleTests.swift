import XCTest
@testable import CrisisCleanup

final class RruleTests: XCTestCase {
    private let allDays: [RruleWeekDay] = [
        .sunday,
        .monday,
        .tuesday,
        .wednesday,
        .thursday,
        .friday,
        .saturday,
    ]

    func testDailyDefaultCoding() {
        let rrule = Rrule(frequency: .daily)
        let rruleString = rrule.rruleString
        XCTAssertEqual("FREQ=DAILY", rruleString)

        let codedDecoded = Rrule.from(rruleString)
        XCTAssertEqual(rrule, codedDecoded)
    }

    func testDailyFullCoding() {
        let until = Date.now.addingTimeInterval(-19.days)
        let rrule = Rrule(
            frequency: .daily,
            until: until,
            interval: 5,
            byDay: allDays
        )
        let rruleString = rrule.rruleString
        // TODO: Test entire string
        XCTAssertTrue(rruleString.hasPrefix("FREQ=DAILY;UNTIL="))
        XCTAssertTrue(rruleString.hasSuffix(";INTERVAL=5"))

        let codedDecoded = Rrule.from(rruleString)
        let expected = Rrule(
            frequency: .daily,
            until: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: until),
            interval: 5
        )
        XCTAssertEqual(expected, codedDecoded)
    }

    func testWeeklyDefaultCoding() {
        let rrule = Rrule(frequency: .weekly)
        let rruleString = rrule.rruleString
        XCTAssertEqual("FREQ=WEEKLY", rruleString)

        let codedDecoded = Rrule.from(rruleString)
        XCTAssertEqual(rrule, codedDecoded)
    }

    func testWeeklyFullCoding() {
        let until = Date.now.addingTimeInterval(-19.days)
        let rrule = Rrule(
            frequency: .weekly,
            until: until,
            interval: 5,
            byDay: allDays
        )
        let rruleString = rrule.rruleString
        // TODO: Test entire string
        XCTAssertTrue(rruleString.hasPrefix("FREQ=WEEKLY;UNTIL="))
        XCTAssertTrue(rruleString.hasSuffix(";INTERVAL=5;BYDAY=SU,MO,TU,WE,TH,FR,SA"))

        let codedDecoded = Rrule.from(rruleString)
        let expected = Rrule(
            frequency: .weekly,
            until: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: until),
            interval: 5,
            byDay: allDays
        )
        XCTAssertEqual(expected, codedDecoded)
    }

    func testFrequencyDecode() {
        let rrule = Rrule.from("FREQ=MONTHLY")
        let expected = Rrule(
            frequency: .weekly
        )
        XCTAssertEqual(expected, rrule)

        let dailyRrule = Rrule.from("FREQ=DAILY")
        let expectedDaily = Rrule(
            frequency: .daily
        )
        XCTAssertEqual(expectedDaily, dailyRrule)

        let weeklyRrule = Rrule.from("FREQ=WEEKLY")
        let expectedWeekly = Rrule(
            frequency: .weekly
        )
        XCTAssertEqual(expectedWeekly, weeklyRrule)
    }
}
