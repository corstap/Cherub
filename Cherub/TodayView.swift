import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: CherubStore
    @State private var showMoonInfo = false

    private var moon: MoonSnapshot { MoonCalculator.snapshot() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CherubHeader(subtitle: Date().formatted(date: .complete, time: .omitted), showSettings: true)

                    VStack(spacing: 14) {
                        HStack(spacing: 18) {
                            MoonGlyph(snapshot: moon, size: 102)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(moon.phaseName)
                                    .font(.system(size: 27, weight: .bold, design: .serif))
                                Button { showMoonInfo = true } label: {
                                    HStack(spacing: 5) {
                                        Text("Moon in \(moon.zodiacSign)")
                                        Image(systemName: "info.circle")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(Color.cherubSage)
                                }
                                Text("Cycle Day \(store.cycleDay()) · \(store.phase().rawValue)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }

                        CycleWheelView(size: 230)

                        HStack(spacing: 12) {
                            ForEach(CyclePhase.allCases, id: \.self) { phase in
                                HStack(spacing: 5) {
                                    Circle().fill(phase.color).frame(width: 8, height: 8)
                                    Text(phase.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    insightCard
                    quickLog
                    patternsPreview
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .background(Color.cherubBackground.ignoresSafeArea())
            .sheet(isPresented: $showMoonInfo) { MoonInfoSheet(snapshot: moon) }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var insightCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: store.phase().symbol)
                .font(.system(size: 22))
                .foregroundStyle(Color.cherubGold)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 5) {
                Text("Today’s Insight")
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundStyle(Color.cherubBurgundy)
                Text("You’re in your \(store.phase().rawValue.lowercased()) phase while the moon is \(moon.phaseName.lowercased()). Log how you feel today and Cherub will look for your own patterns over time.")
                    .font(.subheadline)
                    .foregroundStyle(Color.cherubInk.opacity(0.78))
            }
        }
        .cherubCard()
    }

    private var quickLog: some View {
        let log = store.log()
        return VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Today’s Log")
            HStack(spacing: 6) {
                MetricTile(title: "Energy", icon: "sun.max", value: log.energy, tint: .cherubGold)
                MetricTile(title: "Mood", icon: "face.smiling", value: log.mood, tint: .cherubRose)
                MetricTile(title: "Sleep", icon: "moon.zzz", value: log.sleep, tint: .cherubSage)
                MetricTile(title: "Aches & cramps", icon: "heart", value: log.symptoms, tint: .cherubBurgundy)
            }
            HStack {
                Text("Flow")
                Spacer()
                Text(log.flow?.title ?? "Not logged")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            NavigationLink {
                LogView()
            } label: {
                Text(log.id == DailyLog.key(for: Date()) && (log.energy + log.mood + log.sleep + log.symptoms > 0 || log.flow != nil) ? "Edit today’s log" : "Log how you feel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cherubBurgundy)
            }
        }
        .cherubCard()
    }

    private var patternsPreview: some View {
        let first = store.insights().first!
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Your Patterns")
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: first.icon)
                    .foregroundStyle(Color.cherubBurgundy)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 3) {
                    Text(first.title).font(.headline)
                    Text(first.detail).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .cherubCard()
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
