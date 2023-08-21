import Combine

class ObservableBoolDictionary: ObservableObject, MutableCollection {
    let didChange = PassthroughSubject<Void, Never>()

    var data: Dictionary<String, Bool> = [:] {
        didSet {
            didChange.send(())
        }
    }

    public typealias Index = String

    var startIndex: String = ""
    var endIndex: String = ""

    init(_ data: Dictionary<String, Bool> = [:]) {
        self.data = data
    }

    subscript(position: String) -> Bool {
        get {
            data.keys.contains(position) ? data[position]! : false
        }
        set {
            data[position] = newValue
        }
    }

    func index(after i: String) -> String {
        fatalError("Index after is not supported by \(self)")
    }
}

class ObservableStringDictionary: ObservableObject {
    let didChange = PassthroughSubject<Void, Never>()

    var data: Dictionary<String, String> = [:] {
        didSet {
            didChange.send(())
        }
    }

    public typealias Index = String

    var startIndex: String = ""
    var endIndex: String = ""

    init(data: Dictionary<String, String> = [:]) {
        self.data = data
    }

    subscript(position: String) -> String {
        get {
            data.keys.contains(position) ? data[position]! : ""
        }
        set {
            data[position] = newValue
        }
    }

    func index(after i: String) -> String {
        fatalError("Index after is not supported by \(self)")
    }
}

class ObservableIntDictionary: ObservableObject, MutableCollection {
    let didChange = PassthroughSubject<Void, Never>()

    var data: Dictionary<String, Int> = [:] {
        didSet {
            didChange.send(())
        }
    }

    public typealias Index = String

    var startIndex: String = ""
    var endIndex: String = ""

    init(_ data: Dictionary<String, Int> = [:]) {
        self.data = data
    }

    subscript(position: String) -> Int {
        get {
            data.keys.contains(position) ? data[position]! : 0
        }
        set {
            data[position] = newValue
        }
    }

    func index(after i: String) -> String {
        fatalError("Index after is not supported by \(self)")
    }
}
