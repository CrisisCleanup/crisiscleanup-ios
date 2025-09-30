@testable import CrisisCleanup

public class WorkTypeAnalyzerMock: WorkTypeAnalyzer {
    //MARK: - countUnsyncedClaimCloseWork

    public var countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsThrowableError: Error?
    public var countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsCallsCount = 0
    public var countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsCalled: Bool {
        return countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsCallsCount > 0
    }
    public var countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsReceivedArguments: (orgId: Int64, incidentId: Int64, ignoreWorksiteIds: Set<Int64>)?
    public var countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsReceivedInvocations: [(orgId: Int64, incidentId: Int64, ignoreWorksiteIds: Set<Int64>)] = []
    public var countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsReturnValue: ClaimCloseCounts!
    public var countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsClosure: ((Int64, Int64, Set<Int64>) throws -> ClaimCloseCounts)?

    public func countUnsyncedClaimCloseWork(orgId: Int64, incidentId: Int64, ignoreWorksiteIds: Set<Int64>) throws -> ClaimCloseCounts {
        if let error = countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsThrowableError {
            throw error
        }
        countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsCallsCount += 1
        countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsReceivedArguments = (orgId: orgId, incidentId: incidentId, ignoreWorksiteIds: ignoreWorksiteIds)
        countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsReceivedInvocations.append((orgId: orgId, incidentId: incidentId, ignoreWorksiteIds: ignoreWorksiteIds))
        if let countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsClosure = countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsClosure {
            return try countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsClosure(orgId, incidentId, ignoreWorksiteIds)
        } else {
            return countUnsyncedClaimCloseWorkOrgIdIncidentIdIgnoreWorksiteIdsReturnValue
        }
    }
}
