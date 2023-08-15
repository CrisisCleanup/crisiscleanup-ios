// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension WorksiteQueryState {
	// A default style constructor for the .copy fn to use
	init(
		incidentId: Int64,
		q: String,
		zoom: Double,
		coordinateBounds: CoordinateBounds,
		isTableView: Bool,
		isZoomInteractive: Bool,
		tableViewSort: WorksiteSortBy,
		filters: CasesFilter,
		hasLocationPermission: Bool,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.incidentId = incidentId
		self.q = q
		self.zoom = zoom
		self.coordinateBounds = coordinateBounds
		self.isTableView = isTableView
		self.isZoomInteractive = isZoomInteractive
		self.tableViewSort = tableViewSort
		self.filters = filters
		self.hasLocationPermission = hasLocationPermission
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteQueryState {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteQueryState()
	}

	struct Builder {
		var incidentId: Int64
		var q: String
		var zoom: Double
		var coordinateBounds: CoordinateBounds
		var isTableView: Bool
		var isZoomInteractive: Bool
		var tableViewSort: WorksiteSortBy
		var filters: CasesFilter
		var hasLocationPermission: Bool

		fileprivate init(original: WorksiteQueryState) {
			self.incidentId = original.incidentId
			self.q = original.q
			self.zoom = original.zoom
			self.coordinateBounds = original.coordinateBounds
			self.isTableView = original.isTableView
			self.isZoomInteractive = original.isZoomInteractive
			self.tableViewSort = original.tableViewSort
			self.filters = original.filters
			self.hasLocationPermission = original.hasLocationPermission
		}

		fileprivate func toWorksiteQueryState() -> WorksiteQueryState {
			return WorksiteQueryState(
				incidentId: incidentId,
				q: q,
				zoom: zoom,
				coordinateBounds: coordinateBounds,
				isTableView: isTableView,
				isZoomInteractive: isZoomInteractive,
				tableViewSort: tableViewSort,
				filters: filters,
				hasLocationPermission: hasLocationPermission
			)
		}
	}
}
