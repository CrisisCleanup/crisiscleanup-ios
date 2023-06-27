// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension IncidentDataPullStats {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentDataPullStats {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toIncidentDataPullStats()
	}

	struct Builder {
		var isStarted: Bool
		var incidentId: Int64
		var pullStart: Date
		var dataCount: Int
		var isPagingRequest: Bool
		var requestedCount: Int
		var savedCount: Int
		var isEnded: Bool
		var startProgressAmount: Double
		var countProgressAmount: Double
		var requestStartedAmount: Double
		var saveStartedAmount: Double

		fileprivate init(original: IncidentDataPullStats) {
			self.isStarted = original.isStarted
			self.incidentId = original.incidentId
			self.pullStart = original.pullStart
			self.dataCount = original.dataCount
			self.isPagingRequest = original.isPagingRequest
			self.requestedCount = original.requestedCount
			self.savedCount = original.savedCount
			self.isEnded = original.isEnded
			self.startProgressAmount = original.startProgressAmount
			self.countProgressAmount = original.countProgressAmount
			self.requestStartedAmount = original.requestStartedAmount
			self.saveStartedAmount = original.saveStartedAmount
		}

		fileprivate func toIncidentDataPullStats() -> IncidentDataPullStats {
			return IncidentDataPullStats(
				isStarted: isStarted,
				incidentId: incidentId,
				pullStart: pullStart,
				dataCount: dataCount,
				isPagingRequest: isPagingRequest,
				requestedCount: requestedCount,
				savedCount: savedCount,
				isEnded: isEnded,
				startProgressAmount: startProgressAmount,
				countProgressAmount: countProgressAmount,
				requestStartedAmount: requestStartedAmount,
				saveStartedAmount: saveStartedAmount
			)
		}
	}
}
