import Foundation

public struct IncidentDataSyncParameters {
    static let timeMarkerZero = Date(timeIntervalSince1970: 0)

    let incidentId: Int64
    let syncDataMeasures: SyncDataMeasure
    let boundedRegion: BoundedRegion?
    let boundedSyncAt: Date

    lazy var lastUpdated: Date? = {
        var latest = boundedSyncAt
        for timeMarker in [
            syncDataMeasures.core,
            syncDataMeasures.additional,
        ] {
            if timeMarker.isDeltaSync,
               timeMarker.after > latest {
                latest = timeMarker.after
            }
        }

        return IncidentDataSyncParameters.timeMarkerZero.distance(to: latest) < 1.days ? nil : latest
    }()

    struct SyncDataMeasure {
        static func relative(_ reference: Date = Date.now) -> SyncDataMeasure {
            return SyncDataMeasure(
                core: SyncTimeMarker.relative(reference),
                additional: SyncTimeMarker.relative(reference)
            )
        }

        let core: SyncTimeMarker
        let additional: SyncTimeMarker
    }

    struct SyncTimeMarker {
        static func relative(_ reference: Date = Date.now) -> SyncTimeMarker {
            return SyncTimeMarker(
                before: reference,
                after: reference - 1.seconds
            )
        }

        let before: Date
        let after: Date

        var isDeltaSync: Bool {
            return timeMarkerZero.distance(to: before) < 1.days
        }
    }

    struct BoundedRegion {
        let latitude: Double
        let longitude: Double
        let radius: Double

        lazy var isDefined: Bool = {
            radius > 0 &&
            (latitude != 0.0 || longitude != 0.0) &&
            -90 < latitude &&
            latitude < 90 &&
            -180 <= longitude &&
            longitude <= 180
        }()

        func isSignificantChange(
            _ other: BoundedRegion,
            thresholdMiles: Double = 0.5
        ) -> Bool {
            // ~69 miles in 1 degree. 1/69 ~= 0.0145 (degrees).
            let thresholdDegrees = 0.0145 * thresholdMiles
            return abs(radius - other.radius) > thresholdMiles ||
            abs(latitude - other.latitude) > thresholdDegrees ||
            abs(longitude.cap360 - other.longitude.cap360) > thresholdDegrees
        }
    }
}

extension Double {
    fileprivate var cap360: Double {
        return (self + 360.0).truncatingRemainder(dividingBy: 360.0)
    }
}
