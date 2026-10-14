import Foundation

enum CyclePhase: String, CaseIterable, Codable {
    case menstrual = "Menstrual"
    case follicular = "Follicular"
    case ovulatory = "Ovulatory"
    case luteal = "Luteal"

    var symbol: String {
        switch self {
        case .menstrual: return "drop.fill"
        case .follicular: return "leaf.fill"
        case .ovulatory: return "sun.max.fill"
        case .luteal: return "moon.fill"
        }
    }

    var archetype: String {
        switch self {
        case .menstrual: return "The Oracle"
        case .follicular: return "The Maiden"
        case .ovulatory: return "The Creator"
        case .luteal: return "The Wild Woman"
        }
    }

    var description: String {
        switch self {
        case .menstrual:
            return "A quieter phase for rest, release and noticing what feels important."
        case .follicular:
            return "Energy often begins to return as the body moves toward ovulation."
        case .ovulatory:
            return "A phase often associated with outward energy, connection and creativity."
        case .luteal:
            return "A phase for discernment and turning inward as the next period approaches."
        }
    }
}

struct CycleProfile: Codable {
    var lastPeriodStart: Date
    var averageCycleLength: Int
    var averagePeriodLength: Int

    func cycleDay(on date: Date, calendar: Calendar = .current) -> Int {
        let length = max(averageCycleLength, 1)
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: lastPeriodStart),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        return ((days % length) + length) % length + 1
    }

    func phase(on date: Date) -> CyclePhase {
        let day = cycleDay(on: date)
        if day <= averagePeriodLength { return .menstrual }
        if day <= max(averagePeriodLength + 8, 13) { return .follicular }
        if day <= min(17, averageCycleLength - 10) { return .ovulatory }
        return .luteal
    }

    func cycleStart(on date: Date, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1 - cycleDay(on: date, calendar: calendar), to: start) ?? start
    }

    static var defaultProfile: CycleProfile {
        CycleProfile(
            lastPeriodStart: Calendar.current.date(byAdding: .day, value: -17, to: Date()) ?? Date(),
            averageCycleLength: 29,
            averagePeriodLength: 5
        )
    }
}

enum MenstrualFlow: String, CaseIterable, Codable, Identifiable {
    case none
    case light
    case medium
    case heavy

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct DailyLog: Codable, Identifiable, Equatable {
    var id: String { Self.key(for: date) }
    var date: Date
    var energy: Int
    var mood: Int
    var sleep: Int
    var creativity: Int
    var stress: Int
    var symptoms: Int
    var notes: String
    // Missing in older saved logs; nil is distinct from explicitly choosing None.
    var flow: MenstrualFlow? = nil
    var libido: Int? = nil
    var cyclePhaseAtLog: CyclePhase? = nil
    var cycleStartAtLog: Date? = nil
    var moonPhaseAtLog: LunarPhase? = nil

    var libidoRating: Int {
        get { libido ?? 0 }
        set { libido = newValue == 0 ? nil : newValue }
    }

    static func empty(for date: Date = Date()) -> DailyLog {
        DailyLog(date: date, energy: 0, mood: 0, sleep: 0, creativity: 0, stress: 0, symptoms: 0, notes: "")
    }

    static func key(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct MoonSnapshot {
    let date: Date
    let age: Double
    let fraction: Double
    let illumination: Double
    let phaseName: String
    let zodiacSign: String
    let symbol: String
    let associations: [String]
    let phaseDescription: String
}

struct PatternInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}
