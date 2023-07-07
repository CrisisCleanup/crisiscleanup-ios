
public struct WorksiteSyncResult {
    let changeResults: [ChangeResult]
    let changeIds: ChangeIds

    struct ChangeResult {
        // Local ID
        let id: Int64
        let isSuccessful: Bool
        let isPartiallySuccessful: Bool
        let isFail: Bool
        let error: Error?
    }

    struct ChangeIds {
        let networkWorksiteId: Int64
        let flagIdMap: [Int64: Int64]
        let noteIdMap: [Int64: Int64]
        let workTypeIdMap: [Int64: Int64]
        let workTypeKeyMap: [String: Int64]
        let workTypeRequestIdMap: [String: Int64]
    }

    private func summarizeChanges<T, R>(_ changeMap: [T: R], _ postText: String) -> String {
        changeMap.isEmpty ? "" : "\(changeMap.count) \(postText)"
    }

    func getSummary(_ totalChangeCount: Int) -> String {
        var successCount = 0
        var partialSuccessCount = 0
        var failCount = 0
        changeResults.forEach {
            if $0.isSuccessful { successCount+=1 }
            else if $0.isPartiallySuccessful { partialSuccessCount+=1 }
            else if $0.isFail { failCount+=1 }
        }
        let outcomeSummary = {
            if totalChangeCount > 1 {
                return [
                    "\(totalChangeCount) changes",
                    "  \(successCount) success",
                    "  \(partialSuccessCount) partial",
                    "  \(failCount) fail",
                ].joined(separator: "\n")
            } else {
                return "1 change: " + {
                    if successCount > 0 { return "success" }
                    else if partialSuccessCount > 0 { return "partial" }
                    else if failCount > 0 { return "fail" }
                    else { return "" }
                }()
            }
        }()
        let changeTypeSummary = [
            summarizeChanges(changeIds.flagIdMap, "flags"),
            summarizeChanges(changeIds.noteIdMap, "notes"),
            summarizeChanges(changeIds.workTypeIdMap, "work type IDs"),
            summarizeChanges(changeIds.workTypeKeyMap, "work type keys"),
            summarizeChanges(changeIds.workTypeRequestIdMap, "work type requests"),
        ]
            .filter { $0.isNotBlank }
            .joined(separator: "\n")

        return [
            "Network ID: \(changeIds.networkWorksiteId)",
            outcomeSummary,
            changeTypeSummary
        ]
        .joined(separator: "\n")
    }
}
