import AppKit
import SwiftUI

extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutHash = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed

        guard withoutHash.count == 6,
              let value = Int(withoutHash, radix: 16)
        else {
            self = .accentColor
            return
        }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    var rgbHexString: String {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .controlAccentColor
        let red = Int(round(nsColor.redComponent * 255.0))
        let green = Int(round(nsColor.greenComponent * 255.0))
        let blue = Int(round(nsColor.blueComponent * 255.0))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
