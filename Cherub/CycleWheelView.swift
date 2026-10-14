import SwiftUI

struct CycleWheelView: View {
    @EnvironmentObject private var store: CherubStore
    var size: CGFloat = 250
    var showsArtwork = false

    var body: some View {
        let day = store.cycleDay()
        let phase = store.phase()
        let total = store.profile.averageCycleLength
        let period = min(store.profile.averagePeriodLength, total)
        let follicularEnd = min(max(period + 8, 13), total)
        let ovulatoryEnd = min(max(follicularEnd, min(17, total - 10)), total)

        ZStack {
            if showsArtwork {
                Circle()
                    .fill(Color.cherubPaper)
                    .frame(width: size * 0.64, height: size * 0.64)
                Image("CycleBotanicalRing")
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            } else {
                Circle()
                    .stroke(Color.black.opacity(0.07), lineWidth: 30)
            }

            phaseArc(color: CyclePhase.menstrual.color, start: 0, end: Double(period) / Double(total))
            phaseArc(color: CyclePhase.follicular.color, start: Double(period) / Double(total), end: Double(follicularEnd) / Double(total))
            phaseArc(color: CyclePhase.ovulatory.color, start: Double(follicularEnd) / Double(total), end: Double(ovulatoryEnd) / Double(total))
            phaseArc(color: CyclePhase.luteal.color, start: Double(ovulatoryEnd) / Double(total), end: 1)

            if showsArtwork {
                ForEach(0..<total, id: \.self) { tick in
                    Circle()
                        .fill(Color.cherubGold.opacity(0.8))
                        .frame(width: 2, height: 2)
                        .offset(y: -(size / 2 - 2))
                        .rotationEffect(.degrees(Double(tick) / Double(total) * 360))
                }
            } else {
                Circle()
                    .stroke(Color.cherubGold.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                    .padding(25)
            }

            VStack(spacing: 3) {
                if !showsArtwork {
                    Text("Cycle Day")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                }
                Text(showsArtwork ? "Day \(day)" : "\(day)")
                    .font(showsArtwork ? .custom("Baskerville", size: 25, relativeTo: .title2) : .system(size: 48, weight: .bold, design: .serif))
                    .foregroundStyle(showsArtwork ? Color.cherubInk : Color.cherubBurgundy)
                Text(showsArtwork ? "\(phase.rawValue)\nPhase" : phase.rawValue)
                    .font(.system(size: showsArtwork ? 13 : 16, weight: showsArtwork ? .regular : .medium))
                    .foregroundStyle(showsArtwork ? Color.cherubInk.opacity(0.8) : Color.cherubSage)
                    .multilineTextAlignment(.center)
                if showsArtwork {
                    TinyStar().padding(.top, 3)
                }
            }

            GeometryReader { proxy in
                let radius = min(proxy.size.width, proxy.size.height) / 2 - (showsArtwork ? 2 : 15)
                let angle = Angle.degrees((Double(day - 1) / Double(total)) * 360 - 90)
                let x = proxy.size.width / 2 + CGFloat(cos(angle.radians)) * radius
                let y = proxy.size.height / 2 + CGFloat(sin(angle.radians)) * radius
                Circle()
                    .fill(Color.cherubBurgundy)
                    .frame(width: showsArtwork ? 10 : 14, height: showsArtwork ? 10 : 14)
                    .overlay(Circle().stroke(Color.cherubPaper, lineWidth: 3))
                    .position(x: x, y: y)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cycle day \(day), \(phase.rawValue) Phase")
    }

    private func phaseArc(color: Color, start: Double, end: Double) -> some View {
        Circle()
            .inset(by: showsArtwork ? 2 : 0)
            .trim(from: start, to: end)
            .stroke(color, style: StrokeStyle(lineWidth: showsArtwork ? 2 : 30, lineCap: .butt))
            .rotationEffect(.degrees(-90))
    }
}
