import Foundation

extension Bundle {
    func localizedString(_ key: String) -> String {
        self.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension String {
    var localizedString: String {
        Bundle.module.localizedString(self)
    }
}
