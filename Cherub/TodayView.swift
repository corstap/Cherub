import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: CherubStore
    @State private var showMoonInfo = false

    private var moon: MoonSnapshot { store.selectedMoon }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    CherubHeader(subtitle: nil, showSettings: true)
                    SharedDateNavigator(isCompact: true)
                        .padding(.top, -10)
                    lunarHeader
                    illustratedCycle
                    phaseLegend
                    insightCard
                    quickLog
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.cherubBackground.ignoresSafeArea())
            .sheet(isPresented: $showMoonInfo) { MoonInfoSheet(snapshot: moon) }
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(Color.cherubBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }

    private var lunarHeader: some View {
        VStack(spacing: 4) {
            GeometryReader { proxy in
                ZStack {
                    lunarDecoration
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    Image("CherubDecoration")
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 0.29, height: 122)
                        .rotationEffect(.degrees(-10))
                        .position(x: proxy.size.width * 0.12, y: 58)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    Button { showMoonInfo = true } label: {
                        MoonGlyph(snapshot: moon, size: 96)
                    }
                    .buttonStyle(.plain)
                    .position(x: proxy.size.width / 2, y: 52)
                    .accessibilityHint("Open moon details")
                }
            }
            .frame(height: 112)

            Text(moon.phaseName)
                .font(.custom("Baskerville", size: 25, relativeTo: .title2))
                .foregroundStyle(Color.cherubInk)
            Button { showMoonInfo = true } label: {
                HStack(spacing: 5) {
                    Text("Moon in \(moon.zodiacSign)")
                    Text(zodiacGlyph)
                }
                .font(.system(size: 13))
                .foregroundStyle(Color.cherubInk)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Open moon and zodiac details")
            Text("Cycle Day \(store.cycleDay()) · \(store.phase().rawValue) Phase")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private var zodiacGlyph: String {
        let symbols = ["Aries": "♈︎", "Taurus": "♉︎", "Gemini": "♊︎", "Cancer": "♋︎",
                       "Leo": "♌︎", "Virgo": "♍︎", "Libra": "♎︎", "Scorpio": "♏︎",
                       "Sagittarius": "♐︎", "Capricorn": "♑︎", "Aquarius": "♒︎", "Pisces": "♓︎"]
        return symbols[moon.zodiacSign] ?? ""
    }

    private var lunarDecoration: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<3, id: \.self) { orbit in
                    Ellipse()
                        .trim(from: 0.02, to: 0.4)
                        .stroke(Color.cherubGold.opacity(0.24), lineWidth: 0.6)
                        .frame(width: 88 + CGFloat(orbit) * 8, height: 150 + CGFloat(orbit) * 8)
                        .rotationEffect(.degrees(-25))
                        .position(x: proxy.size.width * 0.87, y: 84)
                }
                AntiqueStarburst()
                    .fill(Color.cherubGold.opacity(0.8))
                    .frame(width: 62, height: 62)
                    .position(x: proxy.size.width * 0.86, y: 35)
                TinyStar()
                    .position(x: proxy.size.width * 0.07, y: 0)
                TinyStar()
                    .position(x: proxy.size.width * 0.82, y: 108)
            }
        }
    }

    private var illustratedCycle: some View {
        ZStack {
            HStack {
                VStack {
                    TinyStar()
                    Spacer()
                    AntiqueStarburst().fill(Color.cherubGold.opacity(0.65)).frame(width: 18, height: 18)
                    Spacer()
                    TinyStar()
                }
                Spacer()
                VStack {
                    TinyStar()
                    Spacer()
                    TinyStar()
                    Spacer()
                    AntiqueStarburst().fill(Color.cherubGold.opacity(0.65)).frame(width: 14, height: 14)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 34)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            CycleWheelView(size: 224, showsArtwork: true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 232)
    }

    private var phaseLegend: some View {
        HStack(spacing: 12) {
            ForEach(CyclePhase.allCases, id: \.self) { phase in
                HStack(spacing: 4) {
                    Circle().fill(phase.color).frame(width: 7, height: 7)
                    Text(phase.rawValue)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var insightCard: some View {
        NavigationLink {
            PatternsView()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sun.max")
                    .font(.system(size: 23, weight: .light))
                    .foregroundStyle(Color.cherubGold)
                    .frame(width: 28)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.isShowingToday ? "Today’s Insight" : "Daily Insight")
                        .font(.custom("Baskerville", size: 19, relativeTo: .headline))
                        .foregroundStyle(Color.cherubInk)
                    Text(store.insights().first?.detail ?? "Log how you feel to explore your own cycle and lunar patterns.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.cherubInk.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color.cherubGold)
                    .padding(.top, 14)
            }
            .cherubCard()
        }
        .buttonStyle(.plain)
    }

    private var quickLog: some View {
        let log = store.log()
        let hasLog = log.energy + log.mood + log.sleep + log.creativity + log.stress + log.symptoms > 0 || log.flow != nil || !log.notes.isEmpty
        let editTitle = store.isShowingToday ? "Edit today’s log" : "Edit this day’s log"
        return VStack(alignment: .leading, spacing: 8) {
            Text(store.isShowingToday ? "Log today" : "Log this day")
                .font(.custom("Baskerville", size: 19, relativeTo: .headline))
                .foregroundStyle(Color.cherubInk)
            HStack(spacing: 6) {
                quickMetric("Energy", icon: "sun.max", value: log.energy, tint: .cherubAmber)
                quickMetric("Mood", icon: "face.smiling", value: log.mood, tint: .cherubLavender)
                quickMetric("Sleep", icon: "moon", value: log.sleep, tint: .cherubPeriwinkle)
                quickMetric("Creativity", icon: "sparkles", value: log.creativity, tint: .cherubViolet)
                quickMetric("Aches &\nCramps", icon: "heart", value: log.symptoms, tint: .cherubBurgundy)
            }
            HStack {
                Text("Flow")
                Spacer()
                Text(log.flow?.title ?? "Not logged")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            NavigationLink {
                LogView()
            } label: {
                Text(hasLog ? editTitle : "Log how you feel")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cherubBurgundy)
            }
        }
    }

    private func quickMetric(_ title: String, icon: String, value: Int, tint: Color) -> some View {
        NavigationLink {
            LogView()
        } label: {
            MetricTile(title: title, icon: icon, value: value, tint: tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(title.replacingOccurrences(of: "\n", with: " "))")
    }
}

struct MoonInfoSheet: View {
    let snapshot: MoonSnapshot
    @EnvironmentObject private var store: CherubStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 18) {
                        MoonGlyph(snapshot: snapshot, size: 88)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(snapshot.phaseName)
                                .font(.system(size: 28, weight: .bold, design: .serif))
                            Text("\(Int((snapshot.illumination * 100).rounded()))% illuminated")
                                .foregroundStyle(.secondary)
                            Text("Moon in \(snapshot.zodiacSign)")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.cherubBurgundy)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "About this phase")
                        Text(snapshot.phaseDescription)
                            .foregroundStyle(Color.cherubInk.opacity(0.8))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Common associations")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                        FlowTags(items: snapshot.associations)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Moon in \(snapshot.zodiacSign)")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                        Text(signMeaning(snapshot.zodiacSign))
                            .foregroundStyle(Color.cherubInk.opacity(0.8))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("In your data")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                        Text(store.insights().first?.detail ?? "Keep logging and Cherub will compare your own entries with the lunar cycle.")
                            .foregroundStyle(Color.cherubInk.opacity(0.8))
                    }
                    .cherubCard()

                    Text("Lunar meanings in Cherub are reflective traditions, not medical claims. Your logged patterns are correlations in your own entries.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 10)
                }
                .padding(20)
            }
            .background(Color.cherubBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.cherubBurgundy)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func signMeaning(_ sign: String) -> String {
        let meanings: [String: String] = [
            "Aries": "Traditionally associated with initiative, heat, directness and starting before overthinking.",
            "Taurus": "Traditionally associated with steadiness, comfort, the senses, beauty and a desire for stability.",
            "Gemini": "Traditionally associated with curiosity, conversation, movement and changing perspective.",
            "Cancer": "Traditionally associated with home, memory, sensitivity, protection and emotional needs.",
            "Leo": "Traditionally associated with expression, play, confidence, creativity and being seen.",
            "Virgo": "Traditionally associated with discernment, details, routines, care and practical adjustment.",
            "Libra": "Traditionally associated with relationship, balance, beauty, reciprocity and social awareness.",
            "Scorpio": "Traditionally associated with intensity, privacy, honesty, transformation and deeper feeling.",
            "Sagittarius": "Traditionally associated with freedom, meaning, exploration, candor and a wider view.",
            "Capricorn": "Traditionally associated with structure, responsibility, boundaries, patience and long-term focus.",
            "Aquarius": "Traditionally associated with independence, experimentation, community and unconventional thinking.",
            "Pisces": "Traditionally associated with imagination, permeability, dreams, compassion and retreat."
        ]
        return meanings[sign] ?? "Astrological traditions associate each lunar sign with a different emotional and symbolic tone."
    }
}

struct FlowTags: View {
    let items: [String]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.cherubRose.opacity(0.13))
                    .clipShape(Capsule())
            }
        }
    }
}
