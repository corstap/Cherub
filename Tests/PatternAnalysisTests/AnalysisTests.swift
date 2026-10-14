import Foundation
import XCTest
@testable import CherubAnalysis

final class AnalysisTests: XCTestCase {
    let anchor = Date(timeIntervalSince1970: 1704110400)
    var profile: CycleProfile {
        CycleProfile(lastPeriodStart: anchor, averageCycleLength: 28, averagePeriodLength: 5)
    }
    func sample(_ index: Int, cycle: Int, phase: CyclePhase = .luteal, moon: LunarPhase = .fullMoon,
                metric: PatternMetric = .sleep, value: Double) -> AnalysisDay {
        AnalysisDay(
            date: anchor.addingTimeInterval(Double(index) * 86_400), cycle: phase, moon: moon,
            cycleID: "cycle-\(cycle)", lunationID: cycle, values: [metric: value], usesCurrentCycleSettings: false
        )
    }
    func repeated(_ effects: [Double], perGroup: Int = 3) -> PatternComparison {
        var days: [AnalysisDay] = []
        for (cycle, effect) in effects.enumerated() {
            let target = effect < 0 ? 1.0 : 5.0
            let control = target - effect
            for day in 0..<perGroup {
                days.append(sample(cycle * 30 + day, cycle: cycle, value: target))
                days.append(sample(cycle * 30 + day + 10, cycle: cycle, moon: .waxingCrescent, value: control))
            }
        }
        return PatternAnalyzer(days: days, through: anchor).comparison(cycle: .luteal, moon: .fullMoon, metric: .sleep)
    }

    func testLegacyLogsDecodeWithoutNewFields() throws {
        let json = #"{"date":0,"energy":3,"mood":4,"sleep":2,"creativity":5,"stress":1,"symptoms":4,"notes":"Existing note"}"#
        let log = try JSONDecoder().decode(DailyLog.self, from: Data(json.utf8))
        XCTAssertNil(log.libido)
        XCTAssertEqual(log.libidoRating, 0)
        XCTAssertNil(log.cyclePhaseAtLog)
        XCTAssertNil(log.moonPhaseAtLog)
        XCTAssertNil(log.cycleStartAtLog)
        XCTAssertEqual(log.notes, "Existing note")
        XCTAssertEqual(log.symptoms, 4)
        XCTAssertEqual(log.creativity, 5)
    }
    func testNewLogRoundTripPreservesLibidoAndContext() throws {
        var log = DailyLog.empty(for: anchor)
        log.libidoRating = 4
        log.flow = MenstrualFlow.none
        log.cyclePhaseAtLog = .luteal
        log.cycleStartAtLog = anchor
        log.moonPhaseAtLog = .fullMoon
        XCTAssertEqual(try JSONDecoder().decode(DailyLog.self, from: JSONEncoder().encode(log)), log)
    }
    func testLibidoCanBeClearedToUnlogged() {
        var log = DailyLog.empty()
        log.libidoRating = 5
        XCTAssertEqual(PatternMetric.libido.value(in: log), 5)
        log.libidoRating = 0
        XCTAssertNil(log.libido)
        XCTAssertNil(PatternMetric.libido.value(in: log))
    }
    func testMissingAndInvalidRatingsAreExcluded() {
        var log = DailyLog.empty()
        for metric in PatternMetric.allCases { XCTAssertNil(metric.value(in: log)) }
        log.energy = 6
        log.sleep = -1
        log.libido = 0
        XCTAssertNil(PatternMetric.energy.value(in: log))
        XCTAssertNil(PatternMetric.sleep.value(in: log))
        XCTAssertNil(PatternMetric.libido.value(in: log))
    }
    func testFlowNoneIsRecordedZero() {
        var log = DailyLog.empty()
        log.flow = MenstrualFlow.none
        XCTAssertEqual(PatternMetric.flow.value(in: log), 0)
        log.flow = .heavy
        XCTAssertEqual(PatternMetric.flow.value(in: log), 3)
    }
    func testEachMetricReadsItsOwnField() {
        var log = DailyLog.empty()
        log.energy = 1; log.mood = 2; log.sleep = 3; log.creativity = 4
        log.stress = 5; log.symptoms = 2; log.libido = 4; log.flow = .medium
        let expected: [PatternMetric: Double] = [.energy: 1, .mood: 2, .sleep: 3, .creativity: 4, .stress: 5, .cramps: 2, .libido: 4, .flow: 2]
        for (metric, value) in expected { XCTAssertEqual(metric.value(in: log), value) }
    }
    func testMatrixHasEightMoonColumnsAndFourCycleRows() {
        XCTAssertEqual(LunarPhase.matrixPhases.count, 8)
        XCTAssertEqual(CyclePhase.allCases.count, 4)
        XCTAssertFalse(LunarPhase.matrixPhases.contains(.waning))
        XCTAssertEqual(PatternMetric.allCases.count, 8)
    }
    func testBroadWaningAndWaxingWindowsDoNotIncludeFullOrNew() {
        XCTAssertTrue(LunarPhase.waning.contains(.waningGibbous))
        XCTAssertTrue(LunarPhase.waning.contains(.lastQuarter))
        XCTAssertTrue(LunarPhase.waning.contains(.waningCrescent))
        XCTAssertFalse(LunarPhase.waning.contains(.fullMoon))
        XCTAssertFalse(LunarPhase.waning.contains(.newMoon))
        XCTAssertTrue(LunarPhase.waxing.contains(.firstQuarter))
        XCTAssertFalse(LunarPhase.waxing.contains(.waningCrescent))
    }
    func testEmptyCellHasNoAverageAndNoClaim() {
        let cell = PatternAnalyzer(days: [], through: anchor).comparison(cycle: .luteal, moon: .fullMoon, metric: .sleep)
        XCTAssertNil(cell.target.mean)
        XCTAssertNil(cell.difference)
        XCTAssertEqual(cell.target.count, 0)
        XCTAssertEqual(cell.strength, .insufficient)
        XCTAssertFalse(cell.isInteresting)
    }
    func testCountsAreMetricSpecific() {
        let days = [sample(0, cycle: 0, value: 2), sample(1, cycle: 0, metric: .energy, value: 5)]
        let engine = PatternAnalyzer(days: days, through: anchor)
        let sleep = engine.comparison(cycle: .luteal, moon: .fullMoon, metric: .sleep)
        XCTAssertEqual(sleep.target.count, 1)
        XCTAssertEqual(sleep.target.mean, 2)
        XCTAssertEqual(engine.comparison(cycle: .luteal, moon: .fullMoon, metric: .energy).target.mean, 5)
    }
    func testControlContainsOnlySameMenstrualPhase() {
        let days = [
            sample(0, cycle: 0, value: 2),
            sample(1, cycle: 0, moon: .waxingCrescent, value: 3),
            sample(2, cycle: 0, phase: .follicular, moon: .waxingCrescent, value: 5)
        ]
        let cell = PatternAnalyzer(days: days, through: anchor).comparison(cycle: .luteal, moon: .fullMoon, metric: .sleep)
        XCTAssertEqual(cell.control.count, 1)
        XCTAssertEqual(cell.control.mean, 3)
        XCTAssertEqual(cell.overallOtherMoons.count, 2)
        XCTAssertEqual(cell.overallOtherMoons.mean, 4)
    }
    func testCycleConfoundingIsVisibleInsteadOfAConfidentMoonClaim() {
        var days: [AnalysisDay] = []
        for cycle in 0..<4 {
            for day in 0..<4 {
                days.append(sample(cycle * 30 + day, cycle: cycle, value: 2))
            }
            days.append(sample(cycle * 30 + 4, cycle: cycle, phase: .follicular, value: 4))
            for day in 5..<13 {
                days.append(sample(cycle * 30 + day, cycle: cycle, moon: .waxingCrescent, value: 2))
                days.append(sample(cycle * 30 + day + 10, cycle: cycle, phase: .follicular, moon: .waxingCrescent, value: 4))
            }
        }
        let cell = PatternAnalyzer(days: days, through: anchor).comparison(cycle: .luteal, moon: .fullMoon, metric: .sleep)
        XCTAssertEqual(cell.overallDifference!, -0.6, accuracy: 0.001)
        XCTAssertEqual(cell.difference, 0)
        XCTAssertTrue(cell.adjustmentMakesDifferenceSmaller)
        XCTAssertEqual(cell.dominantCycle, .luteal)
        XCTAssertEqual(cell.dominantCount, 16)
        XCTAssertEqual(cell.strength, .noClearDifference)
        XCTAssertTrue(cell.isInteresting)
    }
    func testThreeDaysAreNeverEnoughForPossibleOrStrongerPattern() {
        XCTAssertEqual(repeated([-2], perGroup: 3).strength, .insufficient)
    }
    func testManyDaysInOneCycleDoNotCreateStrongEvidence() {
        XCTAssertEqual(repeated([-2], perGroup: 30).strength, .insufficient)
    }
    func testEarlyRepeatedEffectIsOnlyPossible() {
        let comparison = repeated([-2, -2], perGroup: 3)
        XCTAssertEqual(comparison.target.count, 6)
        XCTAssertEqual(comparison.strength, .possible)
        XCTAssertNil(comparison.cycleRange)
    }
    func testStableMultiCycleEffectHasStrongerSupport() {
        let comparison = repeated([-2, -2, -2, -2, -2], perGroup: 3)
        XCTAssertEqual(comparison.target.count, 15)
        XCTAssertEqual(comparison.control.count, 15)
        XCTAssertEqual(comparison.pairedDifferences.count, 5)
        XCTAssertEqual(comparison.strength, .stronger)
        XCTAssertLessThan(comparison.cycleRange!.upperBound, 0)
    }
    func testInconsistentEffectDoesNotBecomeStrongerWithManyDays() {
        let comparison = repeated([-3, 3, -3, 3, -3], perGroup: 3)
        XCTAssertEqual(comparison.strength, .possible)
        XCTAssertLessThan(comparison.cycleRange!.lowerBound, 0)
        XCTAssertGreaterThan(comparison.cycleRange!.upperBound, 0)
    }
    func testSmallDifferenceIsNotLabeledAsStronger() {
        XCTAssertEqual(repeated([-0.1, -0.1, -0.1, -0.1, -0.1]).strength, .noClearDifference)
    }
    func testStrongEvidenceRequiresWithinCyclePairs() {
        var days: [AnalysisDay] = []
        for cycle in 0..<10 {
            for day in 0..<3 {
                days.append(sample(cycle * 30 + day, cycle: cycle,
                                   moon: cycle < 5 ? .fullMoon : .waxingCrescent,
                                   value: cycle < 5 ? 1 : 3))
            }
        }
        let cell = PatternAnalyzer(days: days, through: anchor).comparison(cycle: .luteal, moon: .fullMoon, metric: .sleep)
        XCTAssertEqual(cell.pairedDifferences.count, 0)
        XCTAssertEqual(cell.strength, .possible)
    }
    func testFutureEntriesAndSelectedDateCutoffAreRespected() {
        var yesterday = DailyLog.empty(for: anchor)
        yesterday.energy = 2
        var tomorrow = DailyLog.empty(for: anchor.addingTimeInterval(2 * 86_400))
        tomorrow.energy = 5
        let now = anchor.addingTimeInterval(86_400)
        let engine = PatternAnalyzer(logs: [yesterday, tomorrow], profile: profile, through: tomorrow.date, now: now)
        XCTAssertEqual(engine.days.count, 1)
        XCTAssertEqual(engine.days.first?.values[.energy], 2)
        XCTAssertEqual(PatternAnalyzer(logs: [yesterday, tomorrow], profile: profile, through: anchor.addingTimeInterval(-86_400), now: now).days.count, 0)
    }
    func testDuplicateCalendarDayDoesNotDoubleTheSample() {
        var early = DailyLog.empty(for: anchor)
        early.mood = 1
        var later = DailyLog.empty(for: anchor.addingTimeInterval(3600))
        later.mood = 5
        let engine = PatternAnalyzer(logs: [early, later], profile: profile, through: later.date, now: later.date)
        XCTAssertEqual(engine.days.count, 1)
        XCTAssertEqual(engine.days.first?.values[.mood], 5)
    }
    func testSavedContextSurvivesChangedCycleSettings() {
        var log = DailyLog.empty(for: anchor)
        log.sleep = 3; log.cyclePhaseAtLog = .luteal
        log.cycleStartAtLog = anchor.addingTimeInterval(-18 * 86_400)
        log.moonPhaseAtLog = .fullMoon
        let engine = PatternAnalyzer(logs: [log], profile: profile, through: anchor, now: anchor)
        XCTAssertEqual(engine.days.first?.cycle, .luteal)
        XCTAssertEqual(engine.days.first?.moon, .fullMoon)
        XCTAssertEqual(engine.inferredContextCount, 0)
    }
    func testLegacyCycleContextIsExplicitlyInferred() {
        var log = DailyLog.empty(for: anchor); log.energy = 2
        let engine = PatternAnalyzer(logs: [log], profile: profile, through: anchor, now: anchor)
        XCTAssertEqual(engine.days.first?.cycle, .menstrual)
        XCTAssertEqual(engine.inferredContextCount, 1)
    }
    func testLibidoCanProduceItsOwnComparison() {
        let days = [sample(0, cycle: 0, metric: .libido, value: 4), sample(1, cycle: 0, moon: .newMoon, metric: .libido, value: 2)]
        let cell = PatternAnalyzer(days: days, through: anchor).comparison(cycle: .luteal, moon: .fullMoon, metric: .libido)
        XCTAssertEqual(cell.target.mean, 4)
        XCTAssertEqual(cell.control.mean, 2)
        XCTAssertEqual(cell.difference, 2)
        XCTAssertEqual(cell.strength, .insufficient)
    }
    func testProfileDaysAndCycleStartsAreCalendarBased() {
        let before = Calendar.current.date(byAdding: .day, value: -1, to: anchor)!
        XCTAssertEqual(profile.cycleDay(on: before), 28)
        XCTAssertEqual(profile.phase(on: before), .luteal)
        XCTAssertTrue(Calendar.current.isDate(profile.cycleStart(on: anchor), inSameDayAs: anchor))
    }
    func testWatchSkipsCurrentMatchingWindowAndFindsFutureMatch() throws {
        let cycle = profile.phase(on: anchor)
        let moon = LunarPhase(on: anchor)
        let watch = PatternWatch.create(cycle: cycle, moon: moon, metric: .sleep, profile: profile, now: anchor)
        XCTAssertGreaterThan(watch.eligibleAfter, Calendar.current.startOfDay(for: anchor))
        XCTAssertFalse(watch.isDue(on: anchor, profile: profile, log: .empty(for: anchor)))
        let next = try XCTUnwrap(watch.nextMatch(from: anchor, profile: profile))
        XCTAssertGreaterThan(next, anchor)
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: next)!
        XCTAssertTrue(watch.matches(noon, profile: profile))
        XCTAssertTrue(watch.isDue(on: noon, profile: profile, log: .empty(for: noon)))
    }
    func testAlreadyLoggedMetricClearsReminderButOtherMetricDoesNot() {
        let watch = PatternWatch(cycle: profile.phase(on: anchor), moon: LunarPhase(on: anchor), metric: .libido,
                                 createdAt: anchor.addingTimeInterval(-3600), eligibleAfter: Calendar.current.startOfDay(for: anchor))
        var log = DailyLog.empty(for: anchor)
        log.sleep = 3
        XCTAssertTrue(watch.isDue(on: anchor, profile: profile, log: log))
        log.libido = 2
        XCTAssertFalse(watch.isDue(on: anchor, profile: profile, log: log))
    }
    func testNoFlowCountsAsCompletedWatchEntry() {
        let watch = PatternWatch(cycle: profile.phase(on: anchor), moon: LunarPhase(on: anchor), metric: .flow,
                                 createdAt: anchor.addingTimeInterval(-3600), eligibleAfter: Calendar.current.startOfDay(for: anchor))
        var log = DailyLog.empty(for: anchor); log.flow = MenstrualFlow.none
        XCTAssertFalse(watch.isDue(on: anchor, profile: profile, log: log))
    }
    func testWrongCombinationNeverPrompts() {
        let wrong: CyclePhase = profile.phase(on: anchor) == .luteal ? .menstrual : .luteal
        let watch = PatternWatch(cycle: wrong, moon: LunarPhase(on: anchor), metric: .energy,
                                 createdAt: anchor.addingTimeInterval(-3600), eligibleAfter: anchor.addingTimeInterval(-3600))
        XCTAssertFalse(watch.isDue(on: anchor, profile: profile, log: .empty(for: anchor)))
    }
    func testWatchesPersistWithStableIdentity() throws {
        let watch = PatternWatch.create(cycle: .luteal, moon: .waning, metric: .stress, profile: profile, now: anchor)
        let reopened = try JSONDecoder().decode([PatternWatch].self, from: JSONEncoder().encode([watch]))
        XCTAssertEqual(reopened, [watch])
        XCTAssertEqual(reopened.first?.id, watch.id)
        XCTAssertTrue(watch.moon.contains(.waningCrescent))
    }
}
