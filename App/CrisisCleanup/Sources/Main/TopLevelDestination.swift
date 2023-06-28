import SwiftUI

enum TopLevelDestination: String, Identifiable, CaseIterable {
    case cases
    case menu

    var id: String {
        rawValue
    }

    var titleTranslateKey: String {
        switch self {
        case .cases: return "nav.work"
        case .menu: return "nav.menu"
        }
    }

    var imageName: String {
        switch self {
        case .cases: return "cases"
        case .menu: return "menu"
        }
    }
}
