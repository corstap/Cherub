import Foundation
import Combine

final class CherubStore: ObservableObject {
    @Published var selectedDate = Date()
    @Published var profile: CycleProfile { didSet { saveProfile() } }
    @Published var logs: [String: DailyLog] { didSet { saveLogs() } }
    @Published private(set) var watchedPatterns: [PatternWatch] { didSet { saveWatches() } }
    @Published private(set) var patternNow = Date()
    @Published private var draftLogs: [String: DailyLog] = [:]

    private let profileKey = "cherub.cycleProfile"
    private let logsKey = "cherub.dailyLogs"
    private let watchesKey = "cherub.patternWatches"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(CycleProfile.self, from: data) {
            profile = decoded
        } else {
            profile = .defaultProfile
        }

        if let data = defaults.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([String: DailyLog].self, from: data) {
            logs = decoded
        } else {
            logs = [:]
        }
        if let data = defaults.data(forKey: watchesKey),
           let decoded = try? JSONDecoder().decode([PatternWatch].self, from: data) {
            watchedPatterns = decoded
        } else {
            watchedPatterns = []
        }
    }

    var isShowingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var selectedMoon: MoonSnapshot {
        MoonCalculator.snapshot(for: selectedDate)
    }

    var selectedLogDraft: DailyLog {
        get { draftLogs[DailyLog.key(for: selectedDate)] ?? log() }
        set { draftLogs[newValue.id] = newValue }
    }

    func moveSelectedDate(by days: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
    }

    func returnToToday() {
        selectedDate = Date()
    }

    func cycleDay(on date: Date? = nil) -> Int {
        profile.cycleDay(on: date ?? selectedDate)
    }

    func phase(on date: Date? = nil) -> CyclePhase {
        profile.phase(on: date ?? selectedDate)
    }

    func nextPeriodDate(from date: Date? = nil) -> Date {
        let referenceDate = date ?? selectedDate
        let day = cycleDay(on: referenceDate)
        let daysRemaining = max(profile.averageCycleLength - day + 1, 1)
        return Calendar.current.date(byAdding: .day, value: daysRemaining, to: referenceDate) ?? referenceDate
    }

    func log(for date: Date? = nil) -> DailyLog {
        let referenceDate = date ?? selectedDate
        return logs[DailyLog.key(for: referenceDate)] ?? .empty(for: referenceDate)
    }

    func save(_ log: DailyLog) {
        var captured = log
        let previous = logs[log.id]
        captured.cyclePhaseAtLog = log.cyclePhaseAtLog ?? previous?.cyclePhaseAtLog ?? profile.phase(on: log.date)
        captured.cycleStartAtLog = log.cycleStartAtLog ?? previous?.cycleStartAtLog ?? profile.cycleStart(on: log.date)
        captured.moonPhaseAtLog = log.moonPhaseAtLog ?? previous?.moonPhaseAtLog ?? LunarPhase(on: log.date)
        logs[log.id] = captured
        draftLogs.removeValue(forKey: log.id)
    }

    func patternAnalyzer(through date: Date? = nil) -> PatternAnalyzer {
        PatternAnalyzer(logs: Array(logs.values), profile: profile, through: date ?? selectedDate, now: patternNow)
    }

    func insights(through date: Date? = nil) -> [PatternInsight] {
        let analyzer = patternAnalyzer(through: date)
        let comparisons = PatternMetric.allCases.flatMap { analyzer.interesting(metric: $0) }
            .sorted {
                if $0.strength.rawValue != $1.strength.rawValue { return $0.strength.rawValue > $1.strength.rawValue }
                if $0.target.cycleCount != $1.target.cycleCount { return $0.target.cycleCount > $1.target.cycleCount }
                return $0.id < $1.id
            }
        if comparisons.isEmpty {
            return [PatternInsight(
                icon: "chart.bar", title: "Learning your patterns",
                detail: "Not enough evidence for a clear cycle × moon difference yet. Keep logging across several cycles; each metric is compared within the same menstrual phase."
            )]
        }
        return comparisons.prefix(3).map {
            PatternInsight(icon: "chart.bar", title: "\($0.strength.title) · \($0.metric.title)", detail: $0.shortExplanation)
        }
    }

    func refreshPatternClock(now: Date = Date()) {
        if !Calendar.current.isDate(patternNow, equalTo: now, toGranularity: .minute) { patternNow = now }
    }

    func isWatching(_ comparison: PatternComparison) -> Bool {
        watchedPatterns.contains { $0.id == comparison.id }
    }

    func toggleWatch(_ comparison: PatternComparison) {
        if isWatching(comparison) {
            watchedPatterns.removeAll { $0.id == comparison.id }
        } else {
            watchedPatterns.append(PatternWatch.create(
                cycle: comparison.cycle, moon: comparison.moon, metric: comparison.metric,
                profile: profile, now: patternNow
            ))
        }
    }

    func removeWatch(_ id: String) {
        watchedPatterns.removeAll { $0.id == id }
    }

    func activePatternWatches() -> [PatternWatch] {
        watchedPatterns.filter { $0.isDue(on: patternNow, profile: profile, log: log(for: patternNow)) }
    }

    private func saveWatches() {
        guard let data = try? JSONEncoder().encode(watchedPatterns) else { return }
        defaults.set(data, forKey: watchesKey)
    }

    private func saveProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }

    private func saveLogs() {
        guard let data = try? JSONEncoder().encode(logs) else { return }
        defaults.set(data, forKey: logsKey)
    }
}
