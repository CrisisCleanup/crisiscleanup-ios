// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension Rrule {
	// A default style constructor for the .copy fn to use
	init(
		frequency: RruleFrequency,
		until: Date?,
		interval: Int,
		byDay: [RruleWeekDay],
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.frequency = frequency
		self.until = until
		self.interval = interval
		self.byDay = byDay
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> Rrule {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toRrule()
	}

	struct Builder {
		var frequency: RruleFrequency
		var until: Date?
		var interval: Int
		var byDay: [RruleWeekDay]

		fileprivate init(original: Rrule) {
			self.frequency = original.frequency
			self.until = original.until
			self.interval = original.interval
			self.byDay = original.byDay
		}

		fileprivate func toRrule() -> Rrule {
			return Rrule(
				frequency: frequency,
				until: until,
				interval: interval,
				byDay: byDay
			)
		}
	}
}
