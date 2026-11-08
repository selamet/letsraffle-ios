import CoreImage.CIFilterBuiltins
import SwiftUI

/// Renders a crisp QR code for the given string.
struct QRCodeView: View {
    let content: String

    var body: some View {
        if let image = QRCode.image(for: content) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel(content)
        } else {
            Image(systemName: "qrcode").resizable().scaledToFit()
        }
    }
}

enum QRCode {
    private static let context = CIContext()

    static func image(for content: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(content.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
