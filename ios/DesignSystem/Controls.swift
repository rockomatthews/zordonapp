import SwiftUI
import CoreImage.CIFilterBuiltins

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1)))
            .foregroundStyle(.white)
    }
}


// MARK: - Zordon Theme (blue background, yellow buttons, black text)

enum ZTheme {
    enum Colors {
        static let background = Color(hex: "#0A45F5")
        static let surface = Color(hex: "#0A3BDD")
        static let primary = Color(hex: "#FFC226")
        static let text = Color.black
        static let textSecondary = Color.black.opacity(0.8)
    }

    enum Metrics {
        static let corner: CGFloat = 0
        static let spacing: CGFloat = 16
    }
}

struct ZButtonYellowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
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

    func zOutlined() -> some View {
        self
            .padding(8)
            .background(Color.white)
            .overlay(Rectangle().stroke(ZTheme.Colors.text, lineWidth: 1))
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

// Simple QR view kept in a common file to ensure it's in target
struct ZQRCodeView: View {
    let content: String
    let size: CGFloat

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Image(uiImage: generate())
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .background(ZTheme.Colors.surface)
            .overlay(Rectangle().stroke(ZTheme.Colors.text, lineWidth: 1))
    }

    private func generate() -> UIImage {
        filter.setValue(Data(content.utf8), forKey: "inputMessage")
        guard let outputImage = filter.outputImage else { return UIImage() }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        if let cgimg = context.createCGImage(scaled, from: scaled.extent) {
            return UIImage(cgImage: cgimg)
        }
        return UIImage()
    }
}


