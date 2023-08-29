import SwiftUI

struct CaseView: View {
    let worksite: CaseSummaryResult

    var body: some View {
        HStack {
            if let icon = worksite.icon {
                Image(uiImage: icon)
            }
            VStack {
                let summary = worksite.summary
                let nameNumber = [summary.name, summary.caseNumber].combineTrimText()
                Text(nameNumber)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let address = [
                    summary.address,
                    summary.city,
                    summary.state
                ].combineTrimText()
                Text(address)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExistingWorksitesList: View {
    let worksites: [CaseSummaryResult]
    let onSelect: (CaseSummaryResult) -> Void
    let isEditable: Bool
    private let columns = [GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(worksites, id: \.id) { worksite in
                CaseView(worksite: worksite)
                    .onTapGesture {
                        if isEditable {
                            onSelect(worksite)
                        }
                    }
                    .padding()
            }
        }
    }
}
