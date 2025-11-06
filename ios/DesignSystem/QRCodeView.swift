import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
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


