import SwiftUI

extension Color {
    static let cherubBackground = Color(red: 0.978, green: 0.972, blue: 0.960)
    static let cherubPaper = Color(red: 0.992, green: 0.985, blue: 0.973)
    static let cherubInk = Color(red: 0.105, green: 0.090, blue: 0.095)
    static let cherubBurgundy = Color(red: 0.49, green: 0.035, blue: 0.13)
    static let cherubRose = Color(red: 0.77, green: 0.52, blue: 0.55)
    static let cherubBlush = Color(red: 0.90, green: 0.76, blue: 0.73)
    static let cherubSage = Color(red: 0.36, green: 0.42, blue: 0.37)
    static let cherubGold = Color(red: 0.66, green: 0.52, blue: 0.31)
    static let cherubLine = Color.black.opacity(0.11)
}

struct CherubCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Color.cherubPaper)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.cherubLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension View {
    func cherubCard() -> some View { modifier(CherubCardModifier()) }
}

struct TinyStar: View {
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.cherubGold)
    }
}

struct AntiqueStarburst: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for point in 0..<64 {
            let angle = Double(point) * .pi / 32 - .pi / 2
            let length: CGFloat
            if point.isMultiple(of: 8) {
                length = radius
            } else if point.isMultiple(of: 2) {
                length = radius * 0.56
            } else {
                length = radius * 0.035
            }
            let position = CGPoint(
                x: rect.midX + CGFloat(cos(angle)) * length,
                y: rect.midY + CGFloat(sin(angle)) * length
            )
            if point == 0 { path.move(to: position) } else { path.addLine(to: position) }
        }
        path.closeSubpath()
        return path
    }
}
