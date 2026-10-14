import SwiftUI

extension Color {
    private init(cherubHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    static let cherubBackground = Color(cherubHex: 0xE7E8E1)
    static let cherubPaper = Color.white.opacity(0.55)
    static let cherubInk = Color(cherubHex: 0x000000)
    static let cherubBurgundy = Color(cherubHex: 0x68344B)
    static let cherubLavender = Color(cherubHex: 0xBDB4C2)
    static let cherubOlive = Color(cherubHex: 0xB5B054)
    static let cherubPeriwinkle = Color(cherubHex: 0x8096E8)
    static let cherubRose = cherubLavender
    static let cherubBlush = cherubLavender
    static let cherubSage = cherubPeriwinkle
    static let cherubGold = cherubOlive
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
