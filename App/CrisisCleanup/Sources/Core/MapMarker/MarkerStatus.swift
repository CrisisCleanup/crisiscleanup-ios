internal let statusClaimToStatus: [WorkTypeStatusClaim: CaseStatus] = [
    WorkTypeStatusClaim(.unknown, true): .unknown,
    WorkTypeStatusClaim(.openAssigned, true): .inProgress,
    WorkTypeStatusClaim(.openUnassigned, true): .claimedNotStarted,
    WorkTypeStatusClaim(.openPartiallyCompleted, true): .partiallyCompleted,
    WorkTypeStatusClaim(.openNeedsFollowUp, true): .needsFollowUp,
    WorkTypeStatusClaim(.openUnresponsive, true): .outOfScopeDu,
    WorkTypeStatusClaim(.closedCompleted, true): .completed,
    WorkTypeStatusClaim(.closedIncomplete, true): .incomplete,
    WorkTypeStatusClaim(.closedOutOfScope, true): .outOfScopeDu,
    WorkTypeStatusClaim(.closedDuplicate, true): .outOfScopeDu,
    WorkTypeStatusClaim(.closedDoneByOthers, true): .doneByOthersNhw,
    WorkTypeStatusClaim(.closedNoHelpWanted, true): .doneByOthersNhw,
    WorkTypeStatusClaim(.unknown, false): .unknown,
    WorkTypeStatusClaim(.openAssigned, false): .unclaimed,
    WorkTypeStatusClaim(.openUnassigned, false): .unclaimed,
    WorkTypeStatusClaim(.openPartiallyCompleted, false): .partiallyCompleted,
    WorkTypeStatusClaim(.openNeedsFollowUp, false): .needsFollowUp,
    WorkTypeStatusClaim(.openUnresponsive, false): .outOfScopeDu,
    WorkTypeStatusClaim(.closedCompleted, false): .completed,
    WorkTypeStatusClaim(.closedIncomplete, false): .incomplete,
    WorkTypeStatusClaim(.closedOutOfScope, false): .outOfScopeDu,
    WorkTypeStatusClaim(.closedDuplicate, false): .outOfScopeDu,
    WorkTypeStatusClaim(.closedDoneByOthers, false): .doneByOthersNhw,
    WorkTypeStatusClaim(.closedNoHelpWanted, false): .doneByOthersNhw,
]
