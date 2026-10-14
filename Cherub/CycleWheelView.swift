import SwiftUI

struct CycleWheelView: View {
    @EnvironmentObject private var store: CherubStore
    var size: CGFloat = 250

    var body: some View {
        let day = store.cycleDay()
        let phase = store.phase()
        let total = store.profile.averageCycleLength
        let period = min(store.profile.averagePeriodLength, total)
        let follicularEnd = min(max(period + 8, 13), total)
        let ovulatoryEnd = min(17, total)

        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.07), lineWidth: 30)

            phaseArc(color: CyclePhase.menstrual.color, start: 0, end: Double(period) / Double(total))
            phaseArc(color: CyclePhase.follicular.color, start: Double(period) / Double(total), end: Double(follicularEnd) / Double(total))
            phaseArc(color: CyclePhase.ovulatory.color, start: Double(follicularEnd) / Double(total), end: Double(ovulatoryEnd) / Double(total))
            phaseArc(color: CyclePhase.luteal.color, start: Double(ovulatoryEnd) / Double(total), end: 1)

            Circle()
                .stroke(Color.cherubGold.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                .padding(25)

            VStack(spacing: 3) {
                Text("Cycle Day")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                Text("\(day)")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundStyle(Color.cherubBurgundy)
                Text(phase.rawValue)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(Color.cherubSage)
            }

            GeometryReader { proxy in
                let radius = min(proxy.size.width, proxy.size.height) / 2 - 15
                let angle = Angle.degrees((Double(day - 1) / Double(total)) * 360 - 90)
                let x = proxy.size.width / 2 + CGFloat(cos(angle.radians)) * radius
                let y = proxy.size.height / 2 + CGFloat(sin(angle.radians)) * radius
                Circle()
                    .fill(Color.cherubBurgundy)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.cherubPaper, lineWidth: 3))
                    .position(x: x, y: y)
            }
        }
        .frame(width: size, height: size)
    }

    private func phaseArc(color: Color, start: Double, end: Double) -> some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(color, style: StrokeStyle(lineWidth: 30, lineCap: .butt))
            .rotationEffect(.degrees(-90))
    }
}
