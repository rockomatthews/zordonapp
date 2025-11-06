import SwiftUI

enum ZTheme {
    enum Colors {
        // Dominant blue background, yellow primary, black text
        static let background = Color(hex: "#0A45F5")
        static let surface = Color(hex: "#0A3BDD")
        static let primary = Color(hex: "#FFC226")
        static let text = Color.black
        static let textSecondary = Color.black.opacity(0.8)
    }

    enum Metrics {
        static let corner: CGFloat = 14
        static let spacing: CGFloat = 16
    }
}

struct ZButtonYellowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: ZTheme.Metrics.corner)
                    .fill(ZTheme.Colors.primary.opacity(configuration.isPressed ? 0.85 : 1))
            )
            .foregroundStyle(ZTheme.Colors.text)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 6)
    }
}

extension View {
    func zScreenBackground() -> some View {
        self.background(ZTheme.Colors.background.ignoresSafeArea())
    }

    func zCard() -> some View {
        self
            .padding()
            .background(RoundedRectangle(cornerRadius: ZTheme.Metrics.corner).fill(ZTheme.Colors.surface))
    }
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if s.count == 3 { for (i, c) in s.enumerated() { s.insert(c, at: s.index(s.startIndex, offsetBy: i*2)) } }
        var i: UInt64 = 0
        Scanner(string: s).scanHexInt64(&i)
        let r = Double((i >> 16) & 0xFF) / 255
        let g = Double((i >> 8) & 0xFF) / 255
        let b = Double(i & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}


