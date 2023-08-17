// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import SwiftUI

extension MapMarkerColor {
	// A default style constructor for the .copy fn to use
	init(
		fillLong: Int64,
		strokeLong: Int64,
		fillInt: Int,
		strokeInt: Int,
		fill: Color,
		stroke: Color,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.fillLong = fillLong
		self.strokeLong = strokeLong
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
		var fillLong: Int64
		var strokeLong: Int64
		var fillInt: Int
		var strokeInt: Int
		var fill: Color
		var stroke: Color

		fileprivate init(original: MapMarkerColor) {
			self.fillLong = original.fillLong
			self.strokeLong = original.strokeLong
			self.fillInt = original.fillInt
			self.strokeInt = original.strokeInt
			self.fill = original.fill
			self.stroke = original.stroke
		}

		fileprivate func toMapMarkerColor() -> MapMarkerColor {
			return MapMarkerColor(
				fillLong: fillLong,
				strokeLong: strokeLong,
				fillInt: fillInt,
				strokeInt: strokeInt,
				fill: fill,
				stroke: stroke
			)
		}
	}
}
