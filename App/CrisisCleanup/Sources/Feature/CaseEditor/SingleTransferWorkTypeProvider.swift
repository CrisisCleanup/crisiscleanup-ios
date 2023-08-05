import Combine

class SingleTransferWorkTypeProvider: TransferWorkTypeProvider {
    @Published private var isPendingTransfer = false
    lazy var isPendingTransferPublisher = $isPendingTransfer

    private(set) var transferType: WorkTypeTransferType = .none
    private(set) var workTypes = [WorkType: Bool]()
    var reason = ""

    private(set) var organizationId: Int64 = 0
    private(set) var organizationName = ""
    private(set) var caseNumber = ""

    func startTransfer(
        organizationId: Int64,
        transferType: WorkTypeTransferType,
        workTypes: [WorkType: Bool],
        organizationName: String,
        caseNumber: String
    ) {
        if transferType != .none &&
            workTypes.isNotEmpty
        {
            self.organizationId = organizationId
            reason = ""
            self.transferType = transferType
            self.workTypes = workTypes
            isPendingTransfer = true

            self.organizationName = organizationName
            self.caseNumber = caseNumber
        } else {
            self.transferType = .none
        }
    }

    func clearPendingTransfer() {
        isPendingTransfer = false
    }
}
