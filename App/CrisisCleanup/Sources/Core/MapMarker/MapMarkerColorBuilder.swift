// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import SwiftUI

extension MapMarkerColor {
	// A default style constructor for the .copy fn to use
	init(
		fillInt64: Int64,
		strokeInt64: Int64,
		fillInt: Int,
		strokeInt: Int,
		fill: Color,
		stroke: Color,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.fillInt64 = fillInt64
		self.strokeInt64 = strokeInt64
		self.fillInt = fillInt
		self.strokeInt = strokeInt
		self.fill = fill
		self.stroke = stroke
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> MapMarkerColor {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toMapMarkerColor()
	}

	struct Builder {
		var fillInt64: Int64
		var strokeInt64: Int64
		var fillInt: Int
		var strokeInt: Int
		var fill: Color
		var stroke: Color

		fileprivate init(original: MapMarkerColor) {
			self.fillInt64 = original.fillInt64
			self.strokeInt64 = original.strokeInt64
			self.fillInt = original.fillInt
			self.strokeInt = original.strokeInt
			self.fill = original.fill
			self.stroke = original.stroke
		}

		fileprivate func toMapMarkerColor() -> MapMarkerColor {
			return MapMarkerColor(
				fillInt64: fillInt64,
				strokeInt64: strokeInt64,
				fillInt: fillInt,
				strokeInt: strokeInt,
				fill: fill,
				stroke: stroke
			)
		}
	}
}
