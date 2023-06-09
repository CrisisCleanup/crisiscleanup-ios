enum Disaster: String, Identifiable, CaseIterable {
    case contaminatedWater,
         earthquake,
         fire,
         flood,
         floodRain,
         floodThunderStorm,
         hail,
         hurricane,
         mudSlide,
         other,
         snow,
         tornado,
         tornadoFlood,
         tornadoWindFlood,
         tropicalStorm,
         virus,
         volcano,
         wind

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .contaminatedWater: return "contaminated_water"
        case .earthquake: return "earthquake"
        case .fire: return "fire"
        case .flood: return "flood"
        case .floodRain: return "flood_rain"
        case .floodThunderStorm: return "flood_tstorm"
        case .hail: return "hail"
        case .hurricane: return "hurricane"
        case .mudSlide: return "mud_slide"
        case .other: return "other"
        case .snow: return "snow"
        case .tornado: return "tornado"
        case .tornadoFlood: return "tornado_flood"
        case .tornadoWindFlood: return "flood_tornado_wind"
        case .tropicalStorm: return "tropical_storm"
        case .virus: return "virus"
        case .volcano: return "volcano"
        case .wind: return "wind"
        }
    }
}

private let reverseLookup = Disaster.allCases.associateBy{ $0.literal }
func disasterFromLiteral(_ literal: String) -> Disaster { reverseLookup[literal] ?? Disaster.other }
