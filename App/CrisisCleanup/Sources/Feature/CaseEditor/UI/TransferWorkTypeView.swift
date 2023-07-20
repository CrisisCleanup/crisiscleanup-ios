import SwiftUI

struct TransferWorkTypeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: TransferWorkTypeViewModel

    @State var isKeyboardOpen = false

    var body: some View {
        if viewModel.isTransferable {
            let isSaving = viewModel.isTransferring
            let disabled = isSaving

            VStack {
                ScrollView {
                    VStack {

                        if viewModel.transferType == .request {
                            Text("Request work types")
                        } else {
                            Text("Release work types")
                        }

                        let workTypeSelections = Array(viewModel.transferWorkTypesState.enumerated())
                        ForEach(workTypeSelections, id: \.self.1.key.id) { (index, entry) in
                            let (workType, isSelected) = entry
                            Text("Work type: \(workType.workTypeLiteral) \(isSelected ? "selected" : "not")")

                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)


                if isKeyboardOpen {
                    OpenKeyboardActionsView()
                } else {
                    TransferWorkTypeSaveActions()
                        .disabled(disabled)
                }
            }
            .onReceive(keyboardPublisher) { isVisible in
                isKeyboardOpen = isVisible
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.screenTitle)
                }
            }
            .hideNavBarUnderSpace()
            .onAppear { viewModel.onViewAppear() }
            .onDisappear { viewModel.onViewDisappear() }
            .environmentObject(viewModel)
        } else {
            Text("Invalid state. Go back")
        }
    }
}

struct TransferWorkTypeSaveActions: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        Text("Show cancel/save")
    }
}
