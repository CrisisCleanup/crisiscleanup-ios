enum Disaster: String, Identifiable, CaseIterable {
    case ContaminatedWater
    case Earthquake
    case Fire
    case Flood
    case FloodRain
    case FloodThunderStorm
    case Hail
    case Hurricane
    case MudSlide
    case Other
    case Snow
    case Tornado
    case TornadoFlood
    case TornadoWindFlood
    case TropicalStorm
    case Virus
    case Volcano
    case Wind

    var id: String { rawValue }

    var literal: String {
        switch self {
        case .ContaminatedWater: return "contaminated_water"
        case .Earthquake: return "earthquake"
        case .Fire: return "fire"
        case .Flood: return "flood"
        case .FloodRain: return "flood_rain"
        case .FloodThunderStorm: return "flood_tstorm"
        case .Hail: return "hail"
        case .Hurricane: return "hurricane"
        case .MudSlide: return "mud_slide"
        case .Other: return "other"
        case .Snow: return "snow"
        case .Tornado: return "tornado"
        case .TornadoFlood: return "tornado_flood"
        case .TornadoWindFlood: return "flood_tornado_wind"
        case .TropicalStorm: return "tropical_storm"
        case .Virus: return "virus"
        case .Volcano: return "volcano"
        case .Wind: return "wind"
        }
    }
}

fileprivate let reverseLookup = Disaster.allCases.associateBy{ $0.literal }
func disasterFromLiteral(_ literal: String) -> Disaster { reverseLookup[literal] ?? Disaster.Other
}
