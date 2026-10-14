import SwiftUI

struct MoonView: View {
    private var moon: MoonSnapshot { MoonCalculator.snapshot() }
    private var upcoming: [(String, Date)] { MoonCalculator.upcomingMajorPhases() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    CherubHeader(subtitle: "The Moon")

                    VStack(spacing: 10) {
                        MoonGlyph(snapshot: moon, size: 140)
                        Text(moon.phaseName)
                            .font(.system(size: 30, weight: .bold, design: .serif))
                        Text("\(Int((moon.illumination * 100).rounded()))% illuminated")
                            .foregroundStyle(.secondary)
                        Text("Moon in \(moon.zodiacSign)")
                            .font(.headline)
                            .foregroundStyle(Color.cherubBurgundy)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "The Lunar Cycle")
                        HStack {
                            ForEach(["●", "☽", "◐", "◕", "○", "◔", "◑", "☾"], id: \.self) { glyph in
                                Text(glyph)
                                    .font(.system(size: 23))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        Text(moon.phaseDescription)
                            .font(.subheadline)
                            .foregroundStyle(Color.cherubInk.opacity(0.8))
                    }
                    .cherubCard()

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(text: "Upcoming Phases")
                        ForEach(Array(upcoming.enumerated()), id: \.offset) { _, phase in
                            HStack {
                                Image(systemName: phase.0.contains("Full") ? "moon.circle.fill" : "moon.circle")
                                    .foregroundStyle(Color.cherubBurgundy)
                                Text(phase.0)
                                Spacer()
                                Text(phase.1.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundStyle(.secondary)
                            }
                            if phase.0 != upcoming.last?.0 { Divider() }
                        }
                    }
                    .cherubCard()

                    Text("Moon phase and zodiac calculations are computed on your device. Astrological associations are included for reflection and are not medical guidance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .padding(.bottom, 30)
            }
            .background(Color.cherubBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
