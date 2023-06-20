import Foundation

var dateNowRoundedSeconds: Date {
    let seconds = Date.now.timeIntervalSince1970.rounded()
    return Date(timeIntervalSince1970: seconds)
}
