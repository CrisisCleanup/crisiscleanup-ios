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
		var incidentId: Int64
		var incidentName: String
		var pullType: IncidentPullDataType
		var isIndeterminate: Bool
		var stepTotal: Int
		var currentStep: Int
		var notificationMessage: String
		var isStarted: Bool
		var startTime: Date
		var isEnded: Bool
		var dataCount: Int
		var queryCount: Int
		var savedCount: Int
		var startProgressAmount: Double

		fileprivate init(original: IncidentDataPullStats) {
			self.incidentId = original.incidentId
			self.incidentName = original.incidentName
			self.pullType = original.pullType
			self.isIndeterminate = original.isIndeterminate
			self.stepTotal = original.stepTotal
			self.currentStep = original.currentStep
			self.notificationMessage = original.notificationMessage
			self.isStarted = original.isStarted
			self.startTime = original.startTime
			self.isEnded = original.isEnded
			self.dataCount = original.dataCount
			self.queryCount = original.queryCount
			self.savedCount = original.savedCount
			self.startProgressAmount = original.startProgressAmount
		}

		fileprivate func toIncidentDataPullStats() -> IncidentDataPullStats {
			return IncidentDataPullStats(
				incidentId: incidentId,
				incidentName: incidentName,
				pullType: pullType,
				isIndeterminate: isIndeterminate,
				stepTotal: stepTotal,
				currentStep: currentStep,
				notificationMessage: notificationMessage,
				isStarted: isStarted,
				startTime: startTime,
				isEnded: isEnded,
				dataCount: dataCount,
				queryCount: queryCount,
				savedCount: savedCount,
				startProgressAmount: startProgressAmount
			)
		}
	}
}
