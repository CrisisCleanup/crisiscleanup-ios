import SwiftUI

struct CaseSummaryResult: Identifiable {
    let summary: WorksiteSummary
    let icon: UIImage?
    let networkWorksiteId: Int64

    var id: Int64

    init(_ summary: WorksiteSummary,
         _ icon: UIImage?,
         listItemKey: Int64? = nil
    ) {
        self.summary = summary
        self.icon = icon
        self.networkWorksiteId = summary.networkId
        id = listItemKey ?? networkWorksiteId
    }
}
