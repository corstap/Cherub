import Foundation

enum PatternMetric: String, CaseIterable, Codable, Identifiable {
    case energy, mood, sleep, creativity, stress, cramps, libido, flow
    var id: String { rawValue }
    var title: String {
        switch self {
        case .energy: return "Energy"
        case .mood: return "Mood"
        case .sleep: return "Sleep"
        case .creativity: return "Creativity"
        case .stress: return "Stress"
        case .cramps: return "Aches & Cramps"
        case .libido: return "Libido"
        case .flow: return "Flow"
        }
    }
    var maximum: Double { self == .flow ? 3 : 5 }
    var minimumDifference: Double { self == .flow ? 0.3 : 0.5 }
    var scaleDescription: String {
        self == .flow
            ? "Flow score: None = 0, Light = 1, Medium = 2, Heavy = 3. This is an ordered score, not a measurement of volume."
            : "Average of your 1–5 ratings. Unlogged ratings are excluded; sleep is a rating, not hours."
    }
    func value(in log: DailyLog) -> Double? {
        if self == .flow {
            guard let flow = log.flow else { return nil }
            switch flow {
            case .none: return 0
            case .light: return 1
            case .medium: return 2
            case .heavy: return 3
            }
        }
        let rating: Int
        switch self {
        case .energy: rating = log.energy
        case .mood: rating = log.mood
        case .sleep: rating = log.sleep
        case .creativity: rating = log.creativity
        case .stress: rating = log.stress
        case .cramps: rating = log.symptoms
        case .libido: rating = log.libidoRating
        case .flow: return nil
        }
        return (1...5).contains(rating) ? Double(rating) : nil
    }
}

enum LunarPhase: String, CaseIterable, Codable, Identifiable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"
    // Broader windows support exploratory comparisons and watches, not matrix columns.
    case waxing = "Waxing moon"
    case waning = "Waning moon"
    var id: String { rawValue }
    static let matrixPhases: [LunarPhase] = [
        .newMoon, .waxingCrescent, .firstQuarter, .waxingGibbous,
        .fullMoon, .waningGibbous, .lastQuarter, .waningCrescent
    ]
    init(on date: Date) {
        self = LunarPhase(rawValue: MoonCalculator.phaseName(for: MoonCalculator.phaseFraction(for: date))) ?? .newMoon
    }
    func contains(_ phase: LunarPhase) -> Bool {
        switch self {
        case .waxing: return [.waxingCrescent, .firstQuarter, .waxingGibbous].contains(phase)
        case .waning: return [.waningGibbous, .lastQuarter, .waningCrescent].contains(phase)
        default: return self == phase
        }
    }
    var symbol: String {
        switch self {
        case .newMoon: return "●"
        case .waxingCrescent, .waxing: return "☽"
        case .firstQuarter: return "◐"
        case .waxingGibbous: return "◕"
        case .fullMoon: return "○"
        case .waningGibbous: return "◔"
        case .lastQuarter: return "◑"
        case .waningCrescent, .waning: return "☾"
        }
    }
}

enum PatternStrength: Int {
    case insufficient, noClearDifference, possible, stronger
    var title: String {
        switch self {
        case .insufficient: return "Not enough data yet"
        case .noClearDifference: return "No clear difference"
        case .possible: return "Possible pattern"
        case .stronger: return "Stronger pattern"
        }
    }
}

struct AnalysisDay {
    let date: Date
    let cycle: CyclePhase
    let moon: LunarPhase
    let cycleID: String
    let lunationID: Int
    let values: [PatternMetric: Double]
    let usesCurrentCycleSettings: Bool
}

struct MetricSummary {
    let count: Int
    let mean: Double?
    let cycleCount: Int
    let lunarCycleCount: Int
    init(_ days: [AnalysisDay], metric: PatternMetric) {
        let measured = days.filter { $0.values[metric] != nil }
        let values = measured.compactMap { $0.values[metric] }
        count = values.count
        mean = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
        cycleCount = Set(measured.map(\.cycleID)).count
        lunarCycleCount = Set(measured.map(\.lunationID)).count
    }
    func averageText(for metric: PatternMetric) -> String {
        guard let mean else { return "—" }
        return String(format: "%.1f/%.0f", mean, metric.maximum)
    }
}

struct PatternComparison: Identifiable {
    let cycle: CyclePhase
    let moon: LunarPhase
    let metric: PatternMetric
    let target: MetricSummary
    let control: MetricSummary
    let overallMoon: MetricSummary
    let overallOtherMoons: MetricSummary
    let pairedDifferences: [Double]
    let dominantCycle: CyclePhase?
    let dominantCount: Int
    var id: String { "\(cycle.rawValue)|\(moon.rawValue)|\(metric.rawValue)" }
    var title: String { "\(cycle.rawValue) × \(moon.rawValue)" }
    var difference: Double? {
        guard let a = target.mean, let b = control.mean else { return nil }
        return a - b
    }
    var overallDifference: Double? {
        guard let a = overallMoon.mean, let b = overallOtherMoons.mean else { return nil }
        return a - b
    }
    var pairedMean: Double? {
        pairedDifferences.isEmpty ? nil : pairedDifferences.reduce(0, +) / Double(pairedDifferences.count)
    }
    // Use menstrual-cycle contrasts as the sampling unit, not independent daily ratings.
    // This range is exploratory; it does not establish causation or account for all biases.
    var cycleRange: ClosedRange<Double>? {
        guard pairedDifferences.count >= 3, let mean = pairedMean else { return nil }
        let n = Double(pairedDifferences.count)
        let variance = pairedDifferences.reduce(0) { $0 + pow($1 - mean, 2) } / (n - 1)
        let critical = [12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262,
                        2.228, 2.201, 2.179, 2.160, 2.145, 2.131, 2.120, 2.110, 2.101,
                        2.093, 2.086, 2.080, 2.074, 2.069, 2.064, 2.060, 2.056, 2.052,
                        2.048, 2.045, 2.042]
        let df = pairedDifferences.count - 1
        let t = df <= critical.count ? critical[df - 1] : 2.042
        let margin = t * sqrt(variance / n)
        return (mean - margin)...(mean + margin)
    }
    var hasRepeatedData: Bool {
        target.count >= 5 && control.count >= 5 &&
        target.cycleCount >= 2 && control.cycleCount >= 2 &&
        target.lunarCycleCount >= 2 && control.lunarCycleCount >= 2
    }
    var strength: PatternStrength {
        guard hasRepeatedData, let difference else { return .insufficient }
        guard abs(difference) >= metric.minimumDifference else { return .noClearDifference }
        if target.count >= 15, control.count >= 15,
           target.lunarCycleCount >= 3, control.lunarCycleCount >= 3,
           let mean = pairedMean, abs(mean) >= metric.minimumDifference,
           mean * difference > 0, let range = cycleRange,
           range.lowerBound > 0 || range.upperBound < 0 {
            let consistent = pairedDifferences.filter { $0 * mean > 0 }.count
            if Double(consistent) / Double(pairedDifferences.count) >= 0.75 { return .stronger }
        }
        return .possible
    }
    var adjustmentMakesDifferenceSmaller: Bool {
        guard target.count >= 5, control.count >= 5,
              let raw = overallDifference, let adjusted = difference else { return false }
        return abs(raw) >= metric.minimumDifference && abs(adjusted) < abs(raw) * 0.5
    }
    var isInteresting: Bool {
        guard target.count >= 3 else { return false }
        if strength == .possible || strength == .stronger { return true }
        return adjustmentMakesDifferenceSmaller
    }
    var shortExplanation: String {
        guard target.mean != nil, control.mean != nil else {
            return "Log more \(metric.title.lowercased()) on \(cycle.rawValue.lowercased()) days, both during \(moon.rawValue.lowercased()) and other moon phases."
        }
        let comparison = "\(metric.title) averages \(target.averageText(for: metric)) on \(cycle.rawValue.lowercased()) + \(moon.rawValue.lowercased()) days (\(target.count) days), versus \(control.averageText(for: metric)) on other \(cycle.rawValue.lowercased()) days (\(control.count) days)."
        if adjustmentMakesDifferenceSmaller { return comparison + " The difference is much smaller after comparing the same menstrual phase." }
        return comparison + " " + strength.title + "."
    }
}

struct PatternAnalyzer {
    let days: [AnalysisDay]
    let through: Date
    init(logs: [DailyLog], profile: CycleProfile, through: Date, now: Date = Date()) {
        let calendar = Calendar.current
        self.through = calendar.startOfDay(for: min(through, now))
        // One observation per calendar day. Never use hypothetical future entries.
        var unique: [String: DailyLog] = [:]
        for log in logs where calendar.startOfDay(for: log.date) <= self.through {
            let key = DailyLog.key(for: log.date)
            if let existing = unique[key], existing.date >= log.date { continue }
            unique[key] = log
        }
        days = unique.values.compactMap { log in
            let values = Dictionary(uniqueKeysWithValues: PatternMetric.allCases.compactMap { metric in
                metric.value(in: log).map { (metric, $0) }
            })
            guard !values.isEmpty else { return nil }
            let cycles = log.date.timeIntervalSince(MoonCalculator.referenceNewMoon) / (MoonCalculator.synodicMonth * 86_400)
            return AnalysisDay(
                date: log.date, cycle: log.cyclePhaseAtLog ?? profile.phase(on: log.date),
                moon: log.moonPhaseAtLog ?? LunarPhase(on: log.date),
                cycleID: DailyLog.key(for: log.cycleStartAtLog ?? profile.cycleStart(on: log.date)),
                lunationID: Int(floor(cycles)), values: values,
                usesCurrentCycleSettings: log.cyclePhaseAtLog == nil || log.cycleStartAtLog == nil
            )
        }.sorted { $0.date < $1.date }
    }
    // Also allows deterministic, synthetic datasets in analysis tests.
    init(days: [AnalysisDay], through: Date) { self.days = days; self.through = through }
    var inferredContextCount: Int { days.filter(\.usesCurrentCycleSettings).count }
    func comparison(cycle: CyclePhase, moon: LunarPhase, metric: PatternMetric) -> PatternComparison {
        let measured = days.filter { $0.values[metric] != nil }
        let sameCyclePhase = measured.filter { $0.cycle == cycle }
        let target = sameCyclePhase.filter { moon.contains($0.moon) }
        let control = sameCyclePhase.filter { !moon.contains($0.moon) }
        let overall = measured.filter { moon.contains($0.moon) }
        let other = measured.filter { !moon.contains($0.moon) }
        let groups = Dictionary(grouping: sameCyclePhase, by: \.cycleID)
        let paired = groups.values.compactMap { group -> Double? in
            let a = MetricSummary(group.filter { moon.contains($0.moon) }, metric: metric)
            let b = MetricSummary(group.filter { !moon.contains($0.moon) }, metric: metric)
            guard a.count >= 2, b.count >= 2, let first = a.mean, let second = b.mean else { return nil }
            return first - second
        }
        let phaseGroups: [CyclePhase: [AnalysisDay]] = Dictionary(grouping: overall, by: \.cycle)
        let phaseCounts: [(CyclePhase, Int)] = phaseGroups.map { ($0.key, $0.value.count) }
        let distribution = phaseCounts.sorted { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            return a.0.rawValue < b.0.rawValue
        }
        return PatternComparison(
            cycle: cycle, moon: moon, metric: metric,
            target: MetricSummary(target, metric: metric), control: MetricSummary(control, metric: metric),
            overallMoon: MetricSummary(overall, metric: metric),
            overallOtherMoons: MetricSummary(other, metric: metric), pairedDifferences: paired,
            dominantCycle: distribution.first?.0, dominantCount: distribution.first?.1 ?? 0
        )
    }
    func comparisons(metric: PatternMetric) -> [PatternComparison] {
        CyclePhase.allCases.flatMap { cycle in
            LunarPhase.allCases.map { comparison(cycle: cycle, moon: $0, metric: metric) }
        }
    }
    func interesting(metric: PatternMetric) -> [PatternComparison] {
        comparisons(metric: metric).filter(\.isInteresting).sorted {
            if $0.strength.rawValue != $1.strength.rawValue { return $0.strength.rawValue > $1.strength.rawValue }
            if $0.target.cycleCount != $1.target.cycleCount { return $0.target.cycleCount > $1.target.cycleCount }
            if $0.target.count != $1.target.count { return $0.target.count > $1.target.count }
            return $0.id < $1.id
        }
    }
}

struct PatternWatch: Codable, Identifiable, Equatable {
    let cycle: CyclePhase
    let moon: LunarPhase
    let metric: PatternMetric
    let createdAt: Date
    let eligibleAfter: Date
    var id: String { "\(cycle.rawValue)|\(moon.rawValue)|\(metric.rawValue)" }
    var title: String { "\(cycle.rawValue) × \(moon.rawValue)" }

    func matches(_ date: Date, profile: CycleProfile) -> Bool {
        profile.phase(on: date) == cycle && moon.contains(LunarPhase(on: date))
    }
    static func create(cycle: CyclePhase, moon: LunarPhase, metric: PatternMetric, profile: CycleProfile, now: Date) -> PatternWatch {
        let calendar = Calendar.current
        var eligible = calendar.startOfDay(for: now)
        // "Watch next cycle" must not prompt again in the current matching window.
        if profile.phase(on: now) == cycle && moon.contains(LunarPhase(on: now)) {
            for offset in 1...60 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { break }
                if profile.phase(on: day) != cycle || !moon.contains(LunarPhase(on: day)) {
                    eligible = calendar.startOfDay(for: day)
                    break
                }
            }
        }
        return PatternWatch(cycle: cycle, moon: moon, metric: metric, createdAt: now, eligibleAfter: eligible)
    }
    func isDue(on date: Date, profile: CycleProfile, log: DailyLog) -> Bool {
        date >= createdAt && Calendar.current.startOfDay(for: date) >= eligibleAfter &&
        matches(date, profile: profile) && metric.value(in: log) == nil
    }
    func nextMatch(from date: Date, profile: CycleProfile) -> Date? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        for offset in 0...730 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) else { continue }
            if day >= eligibleAfter, matches(noon, profile: profile) { return day }
        }
        return nil
    }
}
