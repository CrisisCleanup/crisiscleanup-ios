import SwiftUI

struct CollapsibleIcon: View {
    let isCollapsed: Bool

    private func collapseIconName(_ isCollapsed: Bool) -> String {
        isCollapsed ? "chevron.up" : "chevron.down"
    }

    var body: some View {
        Image(systemName: collapseIconName(isCollapsed))
    }
}
