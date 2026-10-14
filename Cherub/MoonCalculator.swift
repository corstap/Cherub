import Foundation

enum MoonCalculator {
    static let synodicMonth = 29.53058867

    static func snapshot(for date: Date = Date()) -> MoonSnapshot {
        let fraction = phaseFraction(for: date)
        let age = fraction * synodicMonth
        let illumination = (1 - cos(2 * .pi * fraction)) / 2
        let phase = phaseName(for: fraction)
        let zodiac = moonZodiacSign(for: date)

        return MoonSnapshot(
            date: date,
            age: age,
            fraction: fraction,
            illumination: illumination,
            phaseName: phase,
            zodiacSign: zodiac,
            symbol: phaseSymbol(for: fraction),
            associations: associations(for: phase),
            phaseDescription: description(for: phase)
        )
    }

    static func phaseFraction(for date: Date) -> Double {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2000
        components.month = 1
        components.day = 6
        components.hour = 18
        components.minute = 14
        let knownNewMoon = components.date ?? Date(timeIntervalSince1970: 947182440)
        let days = date.timeIntervalSince(knownNewMoon) / 86_400
        let cycles = days / synodicMonth
        return cycles - floor(cycles)
    }

    static func phaseName(for fraction: Double) -> String {
        switch fraction {
        case 0..<0.0625, 0.9375...1: return "New Moon"
        case 0.0625..<0.1875: return "Waxing Crescent"
        case 0.1875..<0.3125: return "First Quarter"
        case 0.3125..<0.4375: return "Waxing Gibbous"
        case 0.4375..<0.5625: return "Full Moon"
        case 0.5625..<0.6875: return "Waning Gibbous"
        case 0.6875..<0.8125: return "Last Quarter"
        default: return "Waning Crescent"
        }
    }

    static func phaseSymbol(for fraction: Double) -> String {
        switch fraction {
        case 0..<0.0625, 0.9375...1: return "●"
        case 0.0625..<0.1875: return "☽"
        case 0.1875..<0.3125: return "◐"
        case 0.3125..<0.4375: return "◕"
        case 0.4375..<0.5625: return "○"
        case 0.5625..<0.6875: return "◔"
        case 0.6875..<0.8125: return "◑"
        default: return "☾"
        }
    }

    static func associations(for phase: String) -> [String] {
        switch phase {
        case "New Moon": return ["reset", "intention", "quiet"]
        case "Waxing Crescent": return ["emergence", "curiosity", "building"]
        case "First Quarter": return ["action", "friction", "decision"]
        case "Waxing Gibbous": return ["refinement", "momentum", "preparation"]
        case "Full Moon": return ["visibility", "intensity", "culmination"]
        case "Waning Gibbous": return ["reflection", "integration", "sharing"]
        case "Last Quarter": return ["release", "reassessment", "boundaries"]
        default: return ["rest", "closure", "inward"]
        }
    }

    static func description(for phase: String) -> String {
        switch phase {
        case "New Moon":
            return "The lunar cycle begins in darkness. Symbolically, this phase is often associated with rest, reset and setting intentions."
        case "Waxing Crescent":
            return "Light begins returning after the new moon. This phase is often associated with early momentum, curiosity and building toward something."
        case "First Quarter":
            return "The moon is halfway between new and full. It is often associated with action, adjustment and working through resistance."
        case "Waxing Gibbous":
            return "The moon is approaching fullness. This phase is often associated with refinement, building energy and preparing for a peak."
        case "Full Moon":
            return "The moon is fully illuminated from our perspective. It is often associated with culmination, visibility and heightened awareness."
        case "Waning Gibbous":
            return "The moon has passed fullness and is beginning to wane. This phase is often associated with reflection, processing and integration."
        case "Last Quarter":
            return "The moon is halfway between full and new. This phase is often associated with release, reassessment and clearing space."
        default:
            return "The visible moon is narrowing toward the new moon. This phase is often associated with rest, closure and turning inward."
        }
    }

    static func moonZodiacSign(for date: Date) -> String {
        let jd = julianDay(for: date)
        let t = (jd - 2451545.0) / 36525.0
        let lPrime = normalize(218.3164477 + 481267.88123421 * t)
        let d = normalize(297.8501921 + 445267.1114034 * t)
        let m = normalize(357.5291092 + 35999.0502909 * t)
        let mPrime = normalize(134.9633964 + 477198.8675055 * t)
        let f = normalize(93.2720950 + 483202.0175233 * t)

        func s(_ degrees: Double) -> Double { sin(degrees * .pi / 180) }

        let longitude = normalize(
            lPrime
            + 6.289 * s(mPrime)
            + 1.274 * s(2 * d - mPrime)
            + 0.658 * s(2 * d)
            + 0.214 * s(2 * mPrime)
            - 0.186 * s(m)
            - 0.114 * s(2 * f)
            + 0.059 * s(2 * d - 2 * mPrime)
            + 0.057 * s(2 * d - m - mPrime)
            + 0.053 * s(2 * d + mPrime)
            + 0.046 * s(2 * d - m)
            + 0.041 * s(m - mPrime)
            - 0.035 * s(d)
            - 0.031 * s(m + mPrime)
        )

        let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        let index = Int(floor(longitude / 30.0)) % 12
        return signs[index]
    }

    static func upcomingMajorPhases(from date: Date = Date(), count: Int = 5) -> [(String, Date)] {
        var results: [(String, Date)] = []
        var cursor = date
        var lastName = snapshot(for: cursor).phaseName

        for _ in 0..<90 where results.count < count {
            cursor = Calendar.current.date(byAdding: .day, value: 1, to: cursor) ?? cursor.addingTimeInterval(86_400)
            let name = snapshot(for: cursor).phaseName
            if name != lastName && ["New Moon", "First Quarter", "Full Moon", "Last Quarter"].contains(name) {
                results.append((name, cursor))
            }
            lastName = name
        }
        return results
    }

    private static func julianDay(for date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400.0 + 2440587.5
    }

    private static func normalize(_ angle: Double) -> Double {
        let value = angle.truncatingRemainder(dividingBy: 360)
        return value < 0 ? value + 360 : value
    }
}
