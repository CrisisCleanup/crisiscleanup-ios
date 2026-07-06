import Combine

// For binding dictionary key-values with SwiftUI views
// Allows for toggling data from SwiftUI and observing from view models

class BindingBoolDictionary: ObservableObject {
    @Published var data: [String: Bool] = [:]

    init(_ data: [String: Bool] = [:]) {
        self.data = data
    }

    subscript(key: String) -> Bool {
        get { data[key] ?? false }
        set { data[key] = newValue }
    }
}

class BindingStringDictionary: ObservableObject {
    @Published var data: [String: String] = [:]

    init(_ data: [String: String] = [:]) {
        self.data = data
    }

    subscript(key: String) -> String {
        get { data[key] ?? "" }
        set { data[key] = newValue }
    }
}
