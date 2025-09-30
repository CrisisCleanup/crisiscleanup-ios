// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Combine
import Foundation
@testable import CrisisCleanup

public class IncidentSelectorMock: IncidentSelector {
    public var incidentId: any Publisher<Int64, Never> {
        get {
            incidentsData
                .eraseToAnyPublisher()
                .map { $0.selected.id }
                .eraseToAnyPublisher()
        }
    }

    public var incident: any Publisher<Incident, Never> {
        get {
            incidentsData
                .eraseToAnyPublisher()
                .map { $0.selected }
                .eraseToAnyPublisher()
        }
    }

    public var incidentsData: any Publisher<IncidentsData, Never> {
        get { Just(underlyingIncidentsData) }
    }
    public var underlyingIncidentsData = IncidentsData(
        isLoading: false,
        selected: EmptyIncident,
        incidents: [],
    )

    //MARK: - selectIncident

    public var selectIncidentCallsCount = 0
    public var selectIncidentCalled: Bool {
        return selectIncidentCallsCount > 0
    }
    public var selectIncidentReceivedIncident: Incident?
    public var selectIncidentReceivedInvocations: [Incident] = []
    public var selectIncidentClosure: ((Incident) -> Void)?

    public func selectIncident(_ incident: Incident) {
        selectIncidentCallsCount += 1
        selectIncidentReceivedIncident = incident
        selectIncidentReceivedInvocations.append(incident)
        selectIncidentClosure?(incident)
    }

    //MARK: - submitIncidentChange

    public var submitIncidentChangeCallsCount = 0
    public var submitIncidentChangeCalled: Bool {
        return submitIncidentChangeCallsCount > 0
    }
    public var submitIncidentChangeReceivedIncident: Incident?
    public var submitIncidentChangeReceivedInvocations: [Incident] = []
    public var submitIncidentChangeReturnValue: Bool!
    public var submitIncidentChangeClosure: ((Incident) async -> Bool)?

    public func submitIncidentChange(_ incident: Incident) async -> Bool {
        submitIncidentChangeCallsCount += 1
        submitIncidentChangeReceivedIncident = incident
        submitIncidentChangeReceivedInvocations.append(incident)
        if let submitIncidentChangeClosure = submitIncidentChangeClosure {
            return await submitIncidentChangeClosure(incident)
        } else {
            return submitIncidentChangeReturnValue
        }
    }
}
