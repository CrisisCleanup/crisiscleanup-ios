import SwiftUI

struct CaseSummaryResult {
    let summary: WorksiteSummary
    let icon: UIImage?
    let networkWorksiteId: Int64

    init(_ summary: WorksiteSummary,
         _ icon: UIImage?
    ) {
        self.summary = summary
        self.icon = icon
        self.networkWorksiteId = summary.networkId
    }
}
