import Foundation

public struct CaseHistoryUserEvents {
    let userId: Int64
    let userName: String
    let orgName: String
    let userPhone: String
    let userEmail: String
    let events: [CaseHistoryEvent]
}

public struct CaseHistoryEvent {
    let id: Int64
    let worksiteId: Int64
    let createdAt: Date
    let createdBy: Int64
    let eventKey: String
    let pastTenseDescription: String
    let actorLocationName: String
    let recipientLocationName: String?
}
