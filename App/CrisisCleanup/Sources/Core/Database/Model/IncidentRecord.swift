import Foundation
import GRDB

// sourcery: copyBuilder
struct IncidentRecord: Identifiable, Equatable {
    static let locations = hasMany(
        IncidentLocationRecord.self,
        through: hasMany(IncidentToIncidentLocationRecord.self),
        using: IncidentToIncidentLocationRecord.locations
    )
    static let incidentFormFields = hasMany(IncidentFormFieldRecord.self)

    static let lists = hasMany(ListRecord.self)

    let id: Int64
    let startAt: Date
    let name: String
    let shortName: String
    let caseLabel: String
    let type: String
    let activePhoneNumber: String?
    let turnOnRelease: Bool
    let isArchived: Bool

    func asExternalModel(
        locationIds: [Int64] = [],
        formFields: [IncidentFormField] = []
    ) -> Incident {
        let phoneNumbers = activePhoneNumber?.split(separator: ",").map { String($0).trim() }.filter { $0.isNotBlank } ?? []
        return Incident(
            id: id,
            name: name,
            shortName: shortName,
            caseLabel: caseLabel,
            locationIds: locationIds,
            activePhoneNumbers: phoneNumbers,
            formFields: formFields,
            turnOnRelease: turnOnRelease,
            disasterLiteral: type,
            startAt: startAt
        )
    }
}

// MARK: - Incident Persistence

extension IncidentRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "incident"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             startAt,
             name,
             shortName,
             type,
             activePhoneNumber,
             turnOnRelease,
             isArchived
    }
}

extension DerivableRequest<IncidentRecord> {
    func isNotArchived() -> Self {
        filter(!IncidentRecord.Columns.isArchived)
    }

    func startingAt(_ startAt: Date) -> Self {
        filter(IncidentRecord.Columns.startAt > startAt)
    }

    func orderedByStartAtDesc() -> Self {
        order(IncidentRecord.Columns.startAt.desc)
    }

    func hasActivePhoneNumber() -> Self {
        filter(IncidentRecord.Columns.activePhoneNumber != nil && IncidentRecord.Columns.activePhoneNumber != "")
    }
}

// MARK: - Incident to incident location

struct IncidentToIncidentLocationRecord: Identifiable, Equatable {
    static let locations = belongsTo(IncidentLocationRecord.self)

    let id: Int64
    let incidentLocationId: Int64
}

// MARK: - Incident to incident location Persistence

extension IncidentToIncidentLocationRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "incidentToIncidentLocation"

    fileprivate enum Columns: String, ColumnExpression {
        case id, incidentLocationId
    }

    static func filterByIds(ids: [Int64]) -> SQLSpecificExpressible {
        ids.contains(Columns.id)
    }
}

// MARK: - Incident location

struct IncidentLocationRecord: Identifiable, Equatable {
    var id: Int64
    let location: Int64
}

// MARK: - Incident location Persistence

extension IncidentLocationRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "incidentLocation"

    fileprivate enum Columns: String, ColumnExpression {
        case id, location
    }
}

// MARK: - Incident form field

struct IncidentFormFieldRecord: Identifiable, Equatable {
    static let incident = belongsTo(IncidentRecord.self)

    let id: Int64?
    let incidentId: Int64
    let parentKey: String
    let fieldKey: String
    let label: String
    let htmlType: String
    let dataGroup: String
    let help: String?
    let placeholder: String?
    let readOnlyBreakGlass: Bool
    let valuesDefaultJson: String?
    let isCheckboxDefaultTrue: Bool?
    let orderLabel: Int
    let validation: String?
    let recurDefault: String?
    let valuesJson: String?
    let isRequired: Bool?
    let isReadOnly: Bool?
    let listOrder: Int
    let isInvalidated: Bool
    let selectToggleWorkType: String?

    func asExternalModel() throws -> IncidentFormField {
        let jsonDecoder = JsonDecoderFactory().decoder()
        let formValues: [String: String] = try valuesJson?.isNotBlank == true ? jsonDecoder.decode(
            [String: String].self,
            from: valuesJson!.data(using: .utf8)!
        ) : [:]
        let formValuesDefault: [String: String] = try formValues.isEmpty && valuesDefaultJson?.isNotBlank == true ? jsonDecoder.decode(
            [String: String].self,
            from: valuesDefaultJson!.data(using: .utf8)!
        ) : [:]
        return IncidentFormField(
            label: label,
            htmlType: htmlType,
            group: dataGroup,
            help: help ?? "",
            placeholder: placeholder ?? "",
            validation: validation ?? "",
            valuesDefault: formValuesDefault,
            values: formValues,
            isCheckboxDefaultTrue: isCheckboxDefaultTrue ?? false,
            recurDefault: recurDefault ?? "",
            isRequired: isRequired ?? false,
            isReadOnly: isReadOnly ?? false,
            isReadOnlyBreakGlass: readOnlyBreakGlass,
            labelOrder: orderLabel,
            listOrder: listOrder,
            isInvalidated: isInvalidated,
            fieldKey: fieldKey,
            parentKey: parentKey,
            selectToggleWorkType: selectToggleWorkType ?? ""
        )
    }
}

// MARK: - Incident form field Persistence

extension IncidentFormFieldRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String = "incidentFormField"

    fileprivate enum Columns: String, ColumnExpression {
        case id,
             incidentId,
             parentKey,
             fieldKey,
             label,
             htmlType,
             dataGroup,
             help,
             placeholder,
             readOnlyBreakGlass,
             valuesDefaultJson,
             isCheckboxDefaultTrue,
             orderLabel,
             validation,
             recurDefault,
             valuesJson,
             isRequired,
             isReadOnly,
             listOrder,
             isInvalidated,
             selectToggleWorkType
    }

    static func invalidateUnspecifiedFormFields(
        _ db: Database,
        _ incidentId: Int64,
        _ validFieldKeys: Set<String>
    ) throws {
        try IncidentFormFieldRecord
            .filter(Columns.incidentId == incidentId && !validFieldKeys.contains(Columns.fieldKey))
            .updateAll(db, [Columns.isInvalidated.set(to: true)])
    }
}
