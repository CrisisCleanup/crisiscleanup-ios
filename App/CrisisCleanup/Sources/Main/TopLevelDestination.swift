import SwiftUI

enum TopLevelDestination: String, Identifiable, CaseIterable {
    case cases
    case menu

    var id: String {
        rawValue
    }

    var titleTranslateKey: String {
        switch self {
        case .cases: return "casesVue.cases"
        case .menu: return "nav.menu"
        }
    }

    var titleLocalizationKey: String {
        switch self {
        case .cases: return "Cases nav"
        case .menu: return "Menu nav"
        }
    }

    var imageName: String {
        switch self {
        case .cases: return "cases"
        case .menu: return "menu"
        }
    }
}
