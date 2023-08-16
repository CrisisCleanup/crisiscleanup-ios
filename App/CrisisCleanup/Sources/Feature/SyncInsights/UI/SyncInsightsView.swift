import SwiftUI

struct SyncInsightsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: SyncInsightsViewModel

    var body: some View {
        let isPendingSync = viewModel.worksitesPendingSync.isNotEmpty
        let logs = viewModel.syncLogs
        ScrollView {
            VStack {
                HStack {
                    if isPendingSync {
                        Text("Pending")
                            .fontHeader3()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 0)
                        Spacer()
                        Button {
                            viewModel.syncPending()
                        } label: {
                            Text("Sync")
                        }
                        .disabled(viewModel.isSyncing)
                        .padding(.horizontal)
                    }
                }
                ForEach(viewModel.worksitesPendingSync, id: \.0) { data in
                    Text(data.1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }

                Text("Logs")
                    .fontHeader3()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 0)
                ForEach(logs, id: \.index) { log in
                    let edgeInsets = log.isContinuingLogType
                    ? EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 0)
                    : EdgeInsets(top: 16, leading: 8, bottom: 0, trailing: 8)
                    SyncLogDetailView(log: log)
                        .padding(edgeInsets)
                }
            }
            .hideNavBarUnderSpace()
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct SyncLogDetailView: View {
    let log: SyncLogItem

    var body: some View {
        if !log.isContinuingLogType {
            Text("\(log.syncLog.logType) \(log.relativeTime)")
                .fontHeader4()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 0)
        }
        Text(log.syncLog.message)
            .frame(maxWidth: .infinity, alignment: .leading)
        if log.syncLog.details.isNotBlank {
            Text(log.syncLog.details)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
