import SwiftUI

extension WorksiteSummary {
    func asCaseLocation(_ iconProvider: MapCaseIconProvider) -> CaseSummaryResult {
        var icon: UIImage? = nil
        if let workType = workType {
            icon = iconProvider.getIcon(
                workType.statusClaim,
                workType.workType,
                false
            )
        }

        return CaseSummaryResult(self, icon)
    }
}
