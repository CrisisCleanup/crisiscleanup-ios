// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

@testable import CrisisCleanup

class WorksiteChangeSerializerMock: WorksiteChangeSerializer {

    //MARK: - serialize

    var serializeThrowableError: Error?
    var serializeCallsCount = 0
    var serializeCalled: Bool {
        return serializeCallsCount > 0
    }
    var serializeReceivedArguments: (isDataChange: Bool, worksiteStart: Worksite, worksiteChange: Worksite, flagIdLookup: [Int64: Int64], noteIdLookup: [Int64: Int64], workTypeIdLookup: [Int64: Int64], requestReason: String, requestWorkTypes: [String], releaseReason: String, releaseWorkTypes: [String])?
    var serializeReceivedInvocations: [(isDataChange: Bool, worksiteStart: Worksite, worksiteChange: Worksite, flagIdLookup: [Int64: Int64], noteIdLookup: [Int64: Int64], workTypeIdLookup: [Int64: Int64], requestReason: String, requestWorkTypes: [String], releaseReason: String, releaseWorkTypes: [String])] = []
    var serializeReturnValue: (Int, String)!
    var serializeClosure: ((Bool, Worksite, Worksite, [Int64: Int64], [Int64: Int64], [Int64: Int64], String, [String], String, [String]) throws -> (Int, String))?

    func serialize(_ isDataChange: Bool, worksiteStart: Worksite, worksiteChange: Worksite, flagIdLookup: [Int64: Int64], noteIdLookup: [Int64: Int64], workTypeIdLookup: [Int64: Int64], requestReason: String, requestWorkTypes: [String], releaseReason: String, releaseWorkTypes: [String]) throws -> (Int, String) {
        if let error = serializeThrowableError {
            throw error
        }
        serializeCallsCount += 1
        serializeReceivedArguments = (isDataChange: isDataChange, worksiteStart: worksiteStart, worksiteChange: worksiteChange, flagIdLookup: flagIdLookup, noteIdLookup: noteIdLookup, workTypeIdLookup: workTypeIdLookup, requestReason: requestReason, requestWorkTypes: requestWorkTypes, releaseReason: releaseReason, releaseWorkTypes: releaseWorkTypes)
        serializeReceivedInvocations.append((isDataChange: isDataChange, worksiteStart: worksiteStart, worksiteChange: worksiteChange, flagIdLookup: flagIdLookup, noteIdLookup: noteIdLookup, workTypeIdLookup: workTypeIdLookup, requestReason: requestReason, requestWorkTypes: requestWorkTypes, releaseReason: releaseReason, releaseWorkTypes: releaseWorkTypes))
        if let serializeClosure = serializeClosure {
            return try serializeClosure(isDataChange, worksiteStart, worksiteChange, flagIdLookup, noteIdLookup, workTypeIdLookup, requestReason, requestWorkTypes, releaseReason, releaseWorkTypes)
        } else {
            return serializeReturnValue
        }
    }

}
