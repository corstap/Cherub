import SwiftUI

extension PatternMetric {
    var color: Color {
        switch self {
        case .energy: return .cherubAmber
        case .mood: return .cherubLavender
        case .sleep: return .cherubPeriwinkle
        case .creativity: return .cherubViolet
        case .stress: return .cherubOlive
        case .cramps, .flow: return .cherubBurgundy
        case .libido: return .cherubLibido
        }
    }
}

struct PatternsView: View {
    @EnvironmentObject private var store: CherubStore
    @State private var metric: PatternMetric = .energy
    @State private var focusedComparison: PatternComparison?
    @State private var showLog = false

    var body: some View {
        let analyzer = store.patternAnalyzer()
        let comparisons = analyzer.comparisons(metric: metric)
        let interesting = Array(analyzer.interesting(metric: metric).prefix(3))
        return NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CherubHeader(subtitle: "Your Patterns")
                    SharedDateNavigator()
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Cycle × Moon")
                        Text("Your logged data through \(analyzer.through.formatted(date: .abbreviated, time: .omitted)).")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Picker("Metric", selection: $metric) {
                            ForEach(PatternMetric.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.menu).tint(.cherubBurgundy)
                        Text(metric.scaleDescription).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    matrix(comparisons)
                    comparisonSection(interesting)
                    watchSection
                    evidenceGuide(analyzer)
                }
                .padding(18).padding(.bottom, 30)
            }
            .background(Color.cherubBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $focusedComparison) { PatternDetailView(comparison: $0) }
            .navigationDestination(isPresented: $showLog) { LogView() }
        }
    }

    private func matrix(_ comparisons: [PatternComparison]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Menstrual phase ↓ · Moon phase →").font(.caption.weight(.medium))
            Text("Each cell shows its average and logged-day count. Swipe across and tap a cell for the comparison.")
                .font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 8) {
                    Color.clear.frame(height: 56)
                    ForEach(CyclePhase.allCases, id: \.self) { cycle in
                        Text(cycle.rawValue).font(.system(size: 11, weight: .medium))
                            .frame(width: 72, height: 72, alignment: .leading)
                    }
                }
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(LunarPhase.matrixPhases) { moon in
                                VStack(spacing: 3) {
                                    Text(moon.symbol).font(.title3)
                                    Text(moon.rawValue).font(.system(size: 9)).multilineTextAlignment(.center)
                                }
                                .frame(width: 74, height: 56)
                            }
                        }
                        ForEach(CyclePhase.allCases, id: \.self) { cycle in
                            HStack(spacing: 6) {
                                ForEach(LunarPhase.matrixPhases) { moon in
                                    if let cell = comparisons.first(where: { $0.cycle == cycle && $0.moon == moon }) {
                                        matrixCell(cell)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 5)
                }
            }
        }
        .cherubCard()
    }

    private func matrixCell(_ comparison: PatternComparison) -> some View {
        let mean = comparison.target.mean
        let shade = mean.map { 0.08 + ($0 / metric.maximum) * 0.2 } ?? 0.035
        return Button { focusedComparison = comparison } label: {
            VStack(spacing: 4) {
                Text(mean.map { String(format: "%.1f", $0) } ?? "—").font(.system(size: 17, weight: .semibold))
                Text("\(comparison.target.count) days").font(.system(size: 10))
                Text(cellLabel(comparison.strength)).font(.system(size: 9)).foregroundStyle(.secondary)
            }
            .foregroundStyle(Color.cherubInk).frame(width: 74, height: 72)
            .background(metric.color.opacity(shade))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(comparison.title), \(metric.title), average \(comparison.target.averageText(for: metric)), \(comparison.target.count) logged days, \(comparison.strength.title)")
        .accessibilityHint("Compare with other moon phases during the same menstrual phase")
    }

    private func cellLabel(_ strength: PatternStrength) -> String {
        switch strength {
        case .insufficient: return "More data needed"
        case .noClearDifference: return "No clear difference"
        case .possible: return "Possible"
        case .stronger: return "Stronger"
        }
    }

    private func comparisonSection(_ comparisons: [PatternComparison]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Comparisons to explore")
            if comparisons.isEmpty {
                Text("No clear \(metric.title.lowercased()) pattern yet. Tap a cell to inspect its averages or watch a combination while you collect more data.")
                    .font(.subheadline).foregroundStyle(.secondary).cherubCard()
            }
            ForEach(comparisons) { comparison in
                VStack(alignment: .leading, spacing: 10) {
                    Text(comparison.title).font(.custom("Baskerville", size: 20, relativeTo: .headline))
                    PatternEvidenceBadge(strength: comparison.strength)
                    Text(comparison.shortExplanation).font(.subheadline).foregroundStyle(.secondary)
                    HStack {
                        Button("View comparison") { focusedComparison = comparison }
                        Spacer(minLength: 8)
                        PatternWatchButton(comparison: comparison)
                    }
                    .font(.caption.weight(.semibold)).tint(.cherubBurgundy)
                }
                .cherubCard()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var watchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Watching patterns")
            if store.watchedPatterns.isEmpty {
                Text("Choose “Watch This Pattern” in a comparison. Cherub will flag matching days inside the app so you can test the pattern again.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(store.watchedPatterns) { watchCard($0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func watchCard(_ watch: PatternWatch) -> some View {
        let due = store.activePatternWatches().contains { $0.id == watch.id }
        let next = watch.nextMatch(from: store.patternNow, profile: store.profile)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(watch.metric.title).font(.headline)
                    Text(watch.title).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Button { store.removeWatch(watch.id) } label: { Image(systemName: "xmark.circle") }
                    .accessibilityLabel("Stop watching \(watch.metric.title), \(watch.title)")
            }
            if due {
                Text("This combination is here today. Log \(watch.metric.title.lowercased()) to test it again.").font(.subheadline)
                Button("Log today") { store.returnToToday(); showLog = true }.font(.subheadline.weight(.semibold))
            } else if Calendar.current.startOfDay(for: store.patternNow) >= watch.eligibleAfter,
                      watch.matches(store.patternNow, profile: store.profile),
                      watch.metric.value(in: store.log(for: store.patternNow)) != nil {
                Text("Your \(watch.metric.title.lowercased()) for today is logged. We’ll keep watching future matching days.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if let next {
                Text("Estimated next match: \(next.formatted(date: .abbreviated, time: .omitted)).")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("No estimated match in the next two years with the current cycle settings.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .tint(.cherubBurgundy).cherubCard()
    }

    private func evidenceGuide(_ analyzer: PatternAnalyzer) -> some View {
        DisclosureGroup("How comparisons work") {
            VStack(alignment: .leading, spacing: 9) {
                Text("Possible patterns need at least 5 rated days per group, across at least 2 menstrual and 2 lunar cycles. Stronger patterns need at least 15 days per group, 3 or more matched menstrual cycles, repeated lunar cycles, and a consistent difference whose cycle-level uncertainty range excludes zero.")
                Text("No clear difference means the observed gap is small—not proof that the groups are identical. Missing ratings and future entries are excluded.")
                Text("These are exploratory personal associations. Other factors, selective logging, and chance can explain differences. More data does not prove the moon caused a change.")
                Text("Cycle phases and upcoming matches are estimates from your settings. Lunar phases use Cherub’s approximate local calculation.")
                if analyzer.inferredContextCount > 0 {
                    Text("\(analyzer.inferredContextCount) earlier logged days use your current cycle settings. New logs preserve the estimated phase and cycle context when saved.")
                }
                Text("All analysis and watches stay on this device. Personal comparisons use only your own logs; traditional moon associations are separate on the Moon screen.")
            }
            .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
        }
        .tint(.cherubBurgundy).cherubCard()
    }
}

private struct PatternEvidenceBadge: View {
    let strength: PatternStrength
    var body: some View {
        Text(strength.title).font(.caption.weight(.semibold)).foregroundStyle(Color.cherubBurgundy)
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(Color.cherubBurgundy.opacity(strength == .stronger ? 0.15 : 0.06))
            .clipShape(Capsule())
    }
}

private struct PatternWatchButton: View {
    @EnvironmentObject private var store: CherubStore
    let comparison: PatternComparison
    var body: some View {
        Button(store.isWatching(comparison) ? "Stop watching" : "Watch This Pattern") { store.toggleWatch(comparison) }
            .tint(.cherubBurgundy).accessibilityHint("An on-device reminder appears on a future matching day")
    }
}

private struct PatternDetailView: View {
    let comparison: PatternComparison
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionTitle(text: comparison.metric.title)
                    Text(comparison.title).font(.headline)
                    PatternEvidenceBadge(strength: comparison.strength)
                    Text(comparison.metric.scaleDescription).font(.caption).foregroundStyle(.secondary)
                    overallCard
                    adjustedCard
                    supportCard
                    PatternWatchButton(comparison: comparison).font(.headline)
                    Text("Log a future match even if you feel different from the suggested pattern. Complete, honest entries help test it.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(18)
            }
            .background(Color.cherubBackground.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .tint(.cherubBurgundy)
    }
    private var overallCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("Before comparing cycle phase")
            summaryRow(comparison.moon.rawValue, comparison.overallMoon)
            summaryRow("Other moon phases", comparison.overallOtherMoons)
            if let raw = comparison.overallDifference {
                Text("Overall difference: \(String(format: "%+.1f", raw)) score points.").font(.caption)
            }
            if let dominant = comparison.dominantCycle, comparison.overallMoon.count > 0 {
                Text("\(comparison.dominantCount) of \(comparison.overallMoon.count) logged \(comparison.moon.rawValue.lowercased()) days fell in the \(dominant.rawValue.lowercased()) phase.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .cherubCard()
    }
    private var adjustedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            heading("Compare like cycle phases")
            Text("Only \(comparison.cycle.rawValue.lowercased()) days").font(.caption).foregroundStyle(.secondary)
            summaryRow(comparison.moon.rawValue, comparison.target)
            summaryRow("Other moon phases", comparison.control)
            if let difference = comparison.difference {
                Text("Within-phase difference: \(String(format: "%+.1f", difference)) score points.").font(.caption)
            }
            if comparison.adjustmentMakesDifferenceSmaller {
                Text("The gap becomes much smaller when comparing the same menstrual phase. Menstrual timing may help explain the overall moon comparison.")
                    .font(.subheadline)
            }
        }
        .cherubCard()
    }
    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            heading("How much support?")
            Text("\(comparison.target.count) matching days across \(comparison.target.cycleCount) menstrual cycles and \(comparison.target.lunarCycleCount) lunar cycles.")
            Text("\(comparison.control.count) comparison days in the same menstrual phase.")
            Text("\(comparison.pairedDifferences.count) menstrual cycles have at least two logged days in both groups.")
            if let range = comparison.cycleRange {
                Text("Approximate 95% range across matched cycles: \(String(format: "%+.1f", range.lowerBound)) to \(String(format: "%+.1f", range.upperBound)) score points.")
            } else {
                Text("More matched cycles are needed to estimate how repeatable the difference is.")
            }
            Text("This range uses cycle-to-cycle differences rather than treating every daily rating as independent. It is exploratory and cannot establish cause.")
                .foregroundStyle(.secondary)
        }
        .font(.caption).cherubCard()
    }
    private func heading(_ text: String) -> some View {
        Text(text).font(.custom("Baskerville", size: 20, relativeTo: .headline))
    }
    private func summaryRow(_ title: String, _ summary: MetricSummary) -> some View {
        HStack(alignment: .top) {
            Text(title).font(.subheadline)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.averageText(for: comparison.metric)).font(.headline)
                Text("\(summary.count) logged days").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
