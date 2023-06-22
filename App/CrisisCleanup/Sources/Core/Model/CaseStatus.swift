// TODO Can this be consolidated with WorkTypeStatus? Or are these distinct states?
enum CaseStatus: String, Identifiable, CaseIterable {
    case unknown,
         unclaimed,
         claimedNotStarted,
         inProgress,
         partiallyCompleted,
         needsFollowUp,
         completed,

         // TODO Review colors (and names) on web. There are marker colors and status colors...
         /**
          * Nhw = no help wanted
          * Pc = partially completed
          */
         doneByOthersNhwPc,

         /**
          * Du = Duplicate or unresponsive
          */
         outOfScopeDu,
         incomplete

    var id: String { rawValue }
}
