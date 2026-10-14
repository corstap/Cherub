import SwiftUI

extension Color {
    static let cherubBackground = Color(red: 0.965, green: 0.961, blue: 0.946)
    static let cherubPaper = Color(red: 0.985, green: 0.982, blue: 0.971)
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
            .padding(16)
            .background(Color.cherubPaper)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.cherubLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
