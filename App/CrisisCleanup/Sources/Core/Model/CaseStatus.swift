// TODO Can this be consolidated with WorkTypeStatus? Or are these distinct states?
enum CaseStatus: String, Identifiable, CaseIterable {
    case unknown,
         unclaimed,
         claimedNotStarted,
         inProgress,
         partiallyCompleted,
         needsFollowUp,
         completed,

         /**
          * Nhw = no help wanted
          */
         doneByOthersNhw,

         /**
          * Du = Duplicate or unresponsive
          */
         outOfScopeDu,
         incomplete

    var id: String { rawValue }
}
