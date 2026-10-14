import SwiftUI

struct CherubHeader: View {
    let subtitle: String?
    var showSettings = false
    @State private var showSettingsSheet = false

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("Cherub")
                    .font(.custom("Baskerville", size: 36, relativeTo: .largeTitle))
                    .bold()
                    .foregroundStyle(Color.cherubBurgundy)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.cherubInk.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)

            if showSettings {
                HStack {
                    Spacer()
                    Button { showSettingsSheet = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.cherubInk)
                            .padding(10)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettingsSheet) { SettingsView() }
    }
}

struct SharedDateNavigator: View {
    @EnvironmentObject private var store: CherubStore
    var isCompact = false
    @State private var showingCalendar = false

    var body: some View {
        Group {
            if isCompact {
                navigationControls
            } else {
                navigationControls.cherubCard()
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.cherubBurgundy)
        .tint(.cherubBurgundy)
        .sheet(isPresented: $showingCalendar) {
            NavigationStack {
                DatePicker("Selected date", selection: $store.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .tint(.cherubBurgundy)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showingCalendar = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var compactDateLabel: String {
        if Calendar.current.isDate(store.selectedDate, equalTo: Date(), toGranularity: .year) {
            return store.selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        }
        return store.selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year())
    }

    private var navigationControls: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Button { store.moveSelectedDate(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous day")

                Spacer(minLength: 0)
                if isCompact {
                    Button { showingCalendar = true } label: {
                        Text(compactDateLabel)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.cherubInk)
                            .frame(minHeight: 44)
                    }
                    .accessibilityLabel("Selected date: \(store.selectedDate.formatted(date: .complete, time: .omitted))")
                    .accessibilityHint("Open calendar")
                } else {
                    DatePicker("Selected date", selection: $store.selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                Spacer(minLength: 0)

                Button { store.moveSelectedDate(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Next day")
            }

            if !store.isShowingToday {
                Button("Back to Today") { store.returnToToday() }
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 6)
            }
        }
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .bold, design: .serif))
            .foregroundStyle(Color.cherubInk)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MoonGlyph: View {
    let snapshot: MoonSnapshot
    var size: CGFloat = 90

    var body: some View {
        ZStack {
            moonTexture
            MoonPhaseShadow(fraction: snapshot.fraction)
                .fill(Color.black.opacity(0.92))
                .mask { moonTexture }
            Circle()
                .stroke(Color.cherubGold.opacity(0.45), lineWidth: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .accessibilityLabel(snapshot.phaseName)
        .accessibilityValue("\(Int((snapshot.illumination * 100).rounded()))% illuminated")
    }

    private var moonTexture: some View {
        Image("MoonTexture")
            .resizable()
            .scaledToFit()
    }
}

private struct MoonPhaseShadow: Shape {
    let fraction: Double

    func path(in rect: CGRect) -> Path {
        // Waxing moons are lit on the right; waning moons on the left.
        // Project a spherical terminator rather than sliding a second circle.
        let phase = fraction - floor(fraction)
        let waxing = phase < 0.5
        let curvature = cos(2 * Double.pi * phase) * (waxing ? 1.0 : -1.0)
        let outerX = waxing ? rect.minX : rect.maxX
        var path = Path()
        path.move(to: CGPoint(x: outerX, y: rect.minY))

        for step in 0...128 {
            let y = -1.0 + 2.0 * Double(step) / 128.0
            let halfWidth = sqrt(max(0, 1 - y * y))
            path.addLine(to: CGPoint(
                x: rect.midX + CGFloat(curvature * halfWidth) * rect.width / 2,
                y: rect.midY + CGFloat(y) * rect.height / 2
            ))
        }
        path.addLine(to: CGPoint(x: outerX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct RatingDots: View {
    @Binding var value: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { number in
                Button {
                    value = (value == number ? 0 : number)
                } label: {
                    Circle()
                        .fill(number <= value ? tint : tint.opacity(0.16))
                        .frame(width: 19, height: 19)
                        .overlay(Circle().stroke(number <= value ? Color.cherubBurgundy.opacity(0.4) : tint.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(number) out of 5")
            }
        }
    }
}

struct MetricTile: View {
    let title: String
    let icon: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.08))
                    .overlay(Circle().stroke(tint.opacity(0.22), lineWidth: 0.7))
                    .frame(width: 44, height: 44)
                Image(systemName: icon).foregroundStyle(tint).font(.system(size: 20, weight: .light))
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.cherubInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 24, alignment: .top)
            if value > 0 {
                Text("\(value)/5")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
