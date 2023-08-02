import SwiftUI

let statusOptionColors = [
    WorkTypeStatus.unknown: statusUnknownColor,
    WorkTypeStatus.openAssigned: statusInProgressColor,
    WorkTypeStatus.openUnassigned: statusNotStartedColor,
    WorkTypeStatus.openPartiallyCompleted: statusPartiallyCompletedColor,
    WorkTypeStatus.openNeedsFollowUp: statusNeedsFollowUpColor,
    WorkTypeStatus.openUnresponsive: statusUnresponsiveColor,
    WorkTypeStatus.closedCompleted: statusCompletedColor,
    WorkTypeStatus.closedIncomplete: statusDoneByOthersNhwDiColor,
    WorkTypeStatus.closedOutOfScope: statusOutOfScopeRejectedColor,
    WorkTypeStatus.closedDoneByOthers: statusDoneByOthersNhwDiColor,
    WorkTypeStatus.closedNoHelpWanted: statusDoneByOthersNhwDiColor,
    WorkTypeStatus.closedDuplicate: statusDoneByOthersNhwDiColor,
    WorkTypeStatus.closedRejected: statusOutOfScopeRejectedColor,
]

private struct WorkTypeStatusOption : View {
    @EnvironmentObject var editableView: EditableView

    var translator: KeyTranslator
    var status: WorkTypeStatus
    var showOpenIcon = false
    var isSelected = false

    private let dotSize = 16.0

    var body: some View {
        HStack {
            Circle()
                .frame(width: dotSize, height: dotSize)
                .foregroundColor(statusOptionColors[status] ?? statusUnknownColor)
            Text(translator.t(status.literal))
                .tint(.blue)
                // TODO: Common dimensions
                .frame(height: 48)
                .fontBodySmall()
                .fontWeight(isSelected ? Font.Weight.bold : nil)
            if showOpenIcon {
                DropDownIcon()
            }
        }
        .if (editableView.disabled) { view in
            view.foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkTypeStatusPicker: View {
    @EnvironmentObject var editableView: EditableView

    var translator: KeyTranslator
    var selectedStatus: WorkTypeStatus
    var statusOptions: [WorkTypeStatus]
    var onSelectStatus: (WorkTypeStatus) -> Void

    @State private var showOptions: Bool = false

    var body: some View {
        WorkTypeStatusOption(
            translator: translator,
            status: selectedStatus,
            showOpenIcon: true
        )
        .onTapGesture {
            showOptions.toggle()
        }
        .disabled(editableView.disabled)
        .sheet(isPresented: $showOptions) {
            List {
                ForEach(statusOptions) { status in
                    WorkTypeStatusOption(
                        translator: translator,
                        status: status,
                        isSelected: selectedStatus == status
                    )
                    .onTapGesture {
                        onSelectStatus(status)
                        showOptions = false
                    }
                }
                .padding(.horizontal)
            }

            Button {
                showOptions = false
            } label: {
                Text(translator.t("actions.cancel"))
            }
            .padding()
        }
    }
}
