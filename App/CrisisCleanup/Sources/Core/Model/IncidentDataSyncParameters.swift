import Foundation

// sourcery: copyBuilder, skipCopyInit
public struct IncidentDataSyncParameters: Equatable {
    static let timeMarkerZero = Date(timeIntervalSince1970: 0)

    let incidentId: Int64
    let syncDataMeasures: SyncDataMeasure
    let boundedRegion: BoundedRegion?
    let boundedSyncedAt: Date

    // sourcery:begin: skipCopy
    var lastUpdated: Date? {
        var latest = boundedSyncedAt
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
    }
    // sourcery:end

    // sourcery: copyBuilder, skipCopyInit
    struct SyncDataMeasure: Equatable {
        static func relative(_ reference: Date = Date.now) -> SyncDataMeasure {
            return SyncDataMeasure(
                core: SyncTimeMarker.relative(reference),
                additional: SyncTimeMarker.relative(reference)
            )
        }

        let core: SyncTimeMarker
        let additional: SyncTimeMarker
    }

    // sourcery: copyBuilder, skipCopyInit
    struct SyncTimeMarker: Equatable {
        static func relative(_ reference: Date = Date.now) -> SyncTimeMarker {
            return SyncTimeMarker(
                before: reference,
                after: reference - 1.seconds
            )
        }

        let before: Date
        let after: Date

        // sourcery:begin: skipCopy
        var isDeltaSync: Bool {
            return timeMarkerZero.distance(to: before) < 1.days
        }
        // sourcery:end
    }

    // sourcery: copyBuilder, skipCopyInit
    struct BoundedRegion: Codable, Equatable {
        let latitude: Double
        let longitude: Double
        let radius: Double

        // sourcery:begin: skipCopy
        var isDefined: Bool {
            radius > 0 &&
            (latitude != 0.0 || longitude != 0.0) &&
            -90 < latitude &&
            latitude < 90 &&
            -180 <= longitude &&
            longitude <= 180
        }
        // sourcery:end

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
