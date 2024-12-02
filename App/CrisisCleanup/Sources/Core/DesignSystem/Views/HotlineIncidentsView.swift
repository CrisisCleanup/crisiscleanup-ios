import SwiftUI
import FlowStackLayout

struct HotlineHeaderView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @Binding var isExpanded: Bool

    var body: some View {
        HStack {
            Text(t.t("disasters.hotline"))
                .fontHeader4()
            Spacer()
            CollapsibleIcon(isCollapsed: !isExpanded)
        }
        .onTapGesture {
            isExpanded.toggle()
        }
    }
}

struct HotlineIncidentView: View {
    private let text: String
    private let name: String
    private let activePhoneNumbers: [(Int, String)]
    private let linkifyPhoneNumbers: Bool

    init(
        name: String,
        activePhoneNumbers: [String],
        linkifyPhoneNumbers: Bool = false
    ) {
        let phoneNumbers = activePhoneNumbers.combineTrimText()
        text = "\(name): \(phoneNumbers)"
        self.name = name
        let filteredNumbers = activePhoneNumbers.map { $0.trim() }
            .filter { $0.isNotBlank }
        self.activePhoneNumbers = filteredNumbers.enumerated().map {
            ($0.offset, $0.element)
        }
        self.linkifyPhoneNumbers = linkifyPhoneNumbers
    }

    var body: some View {
        if linkifyPhoneNumbers {
            FlowStack(
                alignment: .leading,
                horizontalSpacing: 0,
                verticalSpacing: appTheme.gridItemSpacing
            ) {
                Text("\(name): ")
                ForEach(activePhoneNumbers, id: \.0) { (index, phoneText) in
                    if index > 0 {
                        Text(", ")
                    }
                    Text(phoneText)
                        .customLink(urlString: "tel:\(phoneText)")
                }
            }
        } else {
            Text(text)
        }
    }
}

struct HotlineIncidentsView: View {
    var incidents: [Incident]
    var linkifyPhoneNumbers = false

    @State var expandHotline = false

    var body: some View {
        if incidents.isNotEmpty {
            VStack(alignment: .leading) {
                HotlineHeaderView(
                    isExpanded: $expandHotline
                )
                .listItemModifier()

                if expandHotline {
                    ForEach(incidents, id: \.id) { incident in
                        HotlineIncidentView(
                            name: incident.shortName,
                            activePhoneNumbers: incident.activePhoneNumbers,
                            linkifyPhoneNumbers: linkifyPhoneNumbers
                        )
                        .listItemPadding()
                    }

                    Rectangle()
                        .fill(.clear)
                        .background(.clear)
                    // TODO: Common dimensions
                        .frame(height: 8.0)
                }
            }
            .background(appTheme.colors.themePrimaryContainer)
        }
    }
}
