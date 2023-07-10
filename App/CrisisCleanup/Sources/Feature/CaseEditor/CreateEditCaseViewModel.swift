import Combine
import Foundation
import SwiftUI

class CreateEditCaseViewModel: ObservableObject {
    let incidentIdIn: Int64
    let worksiteIdIn: Int64?

    init(
        incidentId: Int64,
        worksiteId: Int64?
    ) {
        incidentIdIn = incidentId
        worksiteIdIn = worksiteId
    }
}
