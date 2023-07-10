import Combine

public protocol TransferWorkTypeProvider {
    var isPendingTransferPublisher: Published<Bool>.Publisher { get }
    var transferType: WorkTypeTransferType { get }
    var workTypes: [WorkType: Bool] { get }
    var reason: String { get }

    var organizationId: Int64 { get }
    var organizationName: String { get }
    var caseNumber: String { get }

    func startTransfer(
        organizationId: Int64,
        transferType: WorkTypeTransferType,
        workTypes: [WorkType: Bool],
        organizationName: String,
        caseNumber: String
    )

    func clearPendingTransfer()
}

extension TransferWorkTypeProvider {
    func startTransfer(
        _ organizationId: Int64,
        _ transferType: WorkTypeTransferType,
        _ workTypes: [WorkType: Bool],
        organizationName: String = "",
        caseNumber: String = ""
    ) {
        startTransfer(
            organizationId: organizationId,
            transferType: transferType,
            workTypes: workTypes,
            organizationName: organizationName,
            caseNumber: caseNumber
        )
    }
}

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

public enum WorkTypeTransferType {
    case none,
         request,
         release
}
