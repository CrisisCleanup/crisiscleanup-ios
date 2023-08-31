// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension AppMetrics {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> AppMetrics {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toAppMetrics()
	}

	struct Builder {
		var openBuild: Int64
		var openTimestamp: Date
		var minSupportedVersion: MinSupportedAppVersion

		fileprivate init(original: AppMetrics) {
			self.openBuild = original.openBuild
			self.openTimestamp = original.openTimestamp
			self.minSupportedVersion = original.minSupportedVersion
		}

		fileprivate func toAppMetrics() -> AppMetrics {
			return AppMetrics(
				openBuild: openBuild,
				openTimestamp: openTimestamp,
				minSupportedVersion: minSupportedVersion
			)
		}
	}
}
