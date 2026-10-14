import Foundation
import Combine

final class CherubStore: ObservableObject {
    @Published var selectedDate = Date()
    @Published var profile: CycleProfile { didSet { saveProfile() } }
    @Published var logs: [String: DailyLog] { didSet { saveLogs() } }
    @Published private var draftLogs: [String: DailyLog] = [:]

    private let profileKey = "cherub.cycleProfile"
    private let logsKey = "cherub.dailyLogs"

    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(CycleProfile.self, from: data) {
            profile = decoded
        } else {
            profile = .defaultProfile
        }

        if let data = UserDefaults.standard.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([String: DailyLog].self, from: data) {
            logs = decoded
        } else {
            logs = [:]
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
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: profile.lastPeriodStart)
        let target = calendar.startOfDay(for: date ?? selectedDate)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        let normalized = ((days % profile.averageCycleLength) + profile.averageCycleLength) % profile.averageCycleLength
        return normalized + 1
    }

    func phase(on date: Date? = nil) -> CyclePhase {
        let day = cycleDay(on: date)
        if day <= profile.averagePeriodLength { return .menstrual }
        if day <= max(profile.averagePeriodLength + 8, 13) { return .follicular }
        if day <= min(17, profile.averageCycleLength - 10) { return .ovulatory }
        return .luteal
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
        logs[DailyLog.key(for: log.date)] = log
        draftLogs.removeValue(forKey: log.id)
    }

    func insights(through date: Date? = nil) -> [PatternInsight] {
        let lastDay = Calendar.current.startOfDay(for: date ?? selectedDate)
        let completed = logs.values.filter {
            Calendar.current.startOfDay(for: $0.date) <= lastDay &&
            ($0.energy > 0 || $0.mood > 0 || $0.sleep > 0 || $0.creativity > 0 || $0.stress > 0 || $0.symptoms > 0 || $0.flow != nil)
        }
        guard completed.count >= 5 else {
            return [PatternInsight(icon: "sparkles", title: "Cherub is still learning", detail: "Log a few more days and your own cycle and moon patterns will start appearing here.")]
        }

        var output: [PatternInsight] = []
        let luteal = completed.filter { phase(on: $0.date) == .luteal && $0.energy > 0 }
        let ovulatory = completed.filter { phase(on: $0.date) == .ovulatory && $0.mood > 0 }
        let waning = completed.filter { MoonCalculator.snapshot(for: $0.date).fraction > 0.5 && $0.sleep > 0 }
        let waxing = completed.filter { MoonCalculator.snapshot(for: $0.date).fraction <= 0.5 && $0.creativity > 0 }

        if let avg = average(luteal.map(\.energy)) {
            output.append(PatternInsight(icon: "moon.haze", title: "Luteal energy", detail: "Your average logged energy in the luteal phase is \(String(format: "%.1f", avg))/5."))
        }
        if let avg = average(ovulatory.map(\.mood)) {
            output.append(PatternInsight(icon: "heart", title: "Ovulatory mood", detail: "Your average mood during ovulation is \(String(format: "%.1f", avg))/5."))
        }
        if let avg = average(waning.map(\.sleep)) {
            output.append(PatternInsight(icon: "moon.zzz", title: "Sleep while the moon wanes", detail: "You average \(String(format: "%.1f", avg))/5 for sleep during waning phases."))
        }
        if let avg = average(waxing.map(\.creativity)) {
            output.append(PatternInsight(icon: "sparkles", title: "Creativity while the moon waxes", detail: "Your creativity averages \(String(format: "%.1f", avg))/5 during waxing phases."))
        }

        return output.isEmpty ? [PatternInsight(icon: "sparkles", title: "More data, better patterns", detail: "Keep logging so Cherub can compare your cycle phases with the lunar cycle.")] : output
    }

    private func average(_ values: [Int]) -> Double? {
        let nonzero = values.filter { $0 > 0 }
        guard !nonzero.isEmpty else { return nil }
        return Double(nonzero.reduce(0, +)) / Double(nonzero.count)
    }

    private func saveProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
    }

    private func saveLogs() {
        guard let data = try? JSONEncoder().encode(logs) else { return }
        UserDefaults.standard.set(data, forKey: logsKey)
    }
}
