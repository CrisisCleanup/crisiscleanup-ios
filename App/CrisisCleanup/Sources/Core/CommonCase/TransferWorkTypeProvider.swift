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

public enum WorkTypeTransferType {
    case none,
         request,
         release
}
