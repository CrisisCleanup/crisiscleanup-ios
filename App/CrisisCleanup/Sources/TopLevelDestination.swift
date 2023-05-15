import SwiftUI

enum TopLevelDestination: String, Identifiable, CaseIterable {
    case cases
    case menu

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .cases: return "Cases".localizedString
        case .menu: return "Menu".localizedString
        }
    }

    var imageName: String {
        switch self {
        case .cases: return "cases"
        case .menu: return "menu"
        }
    }
}
