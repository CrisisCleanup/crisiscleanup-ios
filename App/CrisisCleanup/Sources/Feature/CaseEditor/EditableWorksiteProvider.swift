import Atomics
import Combine
import CoreLocation

public protocol EditableWorksiteProvider {
    var incident: Incident { get set }
    var incidentBounds: IncidentBounds { get set }
    var editableWorksite: CurrentValueSubject<Worksite, Never> { get }
    var formFields: [FormFieldNode] { get set }
    var formFieldTranslationLookup: [String : String] { get set }
    var workTypeTranslationLookup: [String : String] { get set }

    var isStale: Bool { get }
    func setStale()
    func takeStale() -> Bool

    func setEditedLocation(coordinates: CLLocationCoordinate2D)
    func clearEditedLocation()

    var isAddressChanged: Bool { get }
    func setAddressChanged(_ worksite: Worksite)
    func takeAddressChanged() -> Bool

    func addNote(_ note: String)
    func takeNote() -> WorksiteNote?

    // TODO: Do
//    var incidentIdChange: any Publisher<Int64, Never> { get }
//    var peekIncidentChange: IncidentChangeData? { get }
    func resetIncidentChange()
//    func setIncidentAddressChanged(_ incident: Incident, _ worksite: Worksite)
//    func updateIncidentChangeWorksite(_ worksite: Worksite)
//    func takeIncidentChanged() -> IncidentChangeData?

    func translate(key: String) -> String?
}

extension EditableWorksiteProvider {
    func getGroupNode(_ key: String) -> FormFieldNode {
        formFields.first { $0.fieldKey == key } ?? EmptyFormFieldNode
    }

    mutating func reset(_ incidentId: Int64 = EmptyIncident.id) {
        incident = EmptyIncident
        incidentBounds = DefaultIncidentBounds
        editableWorksite.value = EmptyWorksite.copy { $0.incidentId = incidentId }
        formFields = []
        formFieldTranslationLookup = [:]
        workTypeTranslationLookup = [:]

        _ = takeStale()
        clearEditedLocation()
        _ = takeAddressChanged()
        resetIncidentChange()
    }
}

class SingleEditableWorksiteProvider: EditableWorksiteProvider, WorksiteLocationEditor {
    var incident: Incident = EmptyIncident
    var incidentBounds: IncidentBounds = DefaultIncidentBounds
    var editableWorksite = CurrentValueSubject<Worksite, Never>(EmptyWorksite)
    var formFields = [FormFieldNode]()
    var formFieldTranslationLookup = [String : String]()
    var workTypeTranslationLookup = [String : String]()

    private var _isStale = ManagedAtomic(false)
    var isStale: Bool {
        get { _isStale.load(ordering: .relaxed) }
    }
    func setStale() {
        _isStale.store(true, ordering: .relaxed)
    }

    func takeStale() -> Bool {
        _isStale.exchange(false, ordering: .acquiring)
    }

    private let editedLocation = ManagedAtomic(OptionalCoordinates())

    private func setCoordinates(_ coordinates: CLLocationCoordinate2D? = nil) {
        let oco = OptionalCoordinates(coordinates)
        editedLocation.store(oco, ordering: .sequentiallyConsistent)
    }

    func setEditedLocation(coordinates: CLLocationCoordinate2D) {
        setCoordinates(coordinates)
    }

    func clearEditedLocation() {
        setCoordinates()
    }

    func takeEditedLocation() -> CLLocationCoordinate2D? {
        editedLocation.exchange(OptionalCoordinates(), ordering: .acquiring).coordinates
    }

    private var _isAddressChanged = ManagedAtomic(false)
    var isAddressChanged: Bool {
        get { _isAddressChanged.load(ordering: .relaxed) }
    }

    func setAddressChanged(_ worksite: Worksite) {
        _ = _isAddressChanged.exchange(true, ordering: .acquiring)
        editableWorksite.value = worksite
    }

    func takeAddressChanged() -> Bool {
        _isAddressChanged.exchange(false, ordering: .acquiring)
    }

    private let addNoteLock = NSLock()
    private var uncommitedNote: WorksiteNote? = nil

    func addNote(_ note: String) {
        if note.isNotBlank {
            addNoteLock.withLock {
                uncommitedNote = WorksiteNote.create().copy { $0.note = note }
            }
        }
    }

    func takeNote() -> WorksiteNote? {
        return addNoteLock.withLock {
            if let note = uncommitedNote {
                uncommitedNote = nil
                return note
            }
            return nil
        }
    }

    func resetIncidentChange() {
        // TODO: Do
    }

    func translate(key: String) -> String? {
        formFieldTranslationLookup[key] ?? workTypeTranslationLookup[key]
    }
}

class OptionalCoordinates: AtomicOptionalWrappable {
    typealias AtomicOptionalRepresentation = AtomicOptionalReferenceStorage<OptionalCoordinates>

    typealias AtomicRepresentation = AtomicReferenceStorage<OptionalCoordinates>

    let coordinates: CLLocationCoordinate2D?

    init(_ coordinates: CLLocationCoordinate2D? = nil) {
        self.coordinates = coordinates
    }
}
