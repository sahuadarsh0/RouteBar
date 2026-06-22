import AppKit
import SwiftUI

struct AccessBrandIcon: View {
    var size: CGFloat = 22
    var showsShadow = false

    var body: some View {
        Image(nsImage: Self.statusImage)
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .fixedSize()
            .shadow(color: .black.opacity(showsShadow ? 0.28 : 0), radius: size * 0.18, y: size * 0.09)
            .accessibilityHidden(true)
    }

    static func installApplicationIcon() {
        if let iconURL = Bundle.main.url(forResource: "AccessControls", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = icon
            return
        }

        NSApplication.shared.applicationIconImage = statusImage
    }

    private static let statusImage: NSImage = {
        let url = Bundle.main.url(forResource: "AccessControlsStatusIcon", withExtension: "png")
            ?? Bundle.module.url(forResource: "AccessControlsStatusIcon", withExtension: "png")

        guard let url, let image = NSImage(contentsOf: url) else {
            return fallbackImage
        }

        image.isTemplate = false
        return image
    }()

    private static let fallbackImage: NSImage = {
        let image = NSImage(size: NSSize(width: 64, height: 64))
        image.lockFocus()
        NSColor.systemOrange.setFill()
        NSBezierPath(roundedRect: NSRect(x: 4, y: 4, width: 56, height: 56), xRadius: 14, yRadius: 14).fill()
        NSColor.black.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 7
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: NSPoint(x: 17, y: 25))
        path.line(to: NSPoint(x: 29, y: 39))
        path.line(to: NSPoint(x: 38, y: 30))
        path.line(to: NSPoint(x: 49, y: 45))
        path.move(to: NSPoint(x: 38, y: 45))
        path.line(to: NSPoint(x: 49, y: 45))
        path.line(to: NSPoint(x: 49, y: 34))
        path.stroke()
        image.unlockFocus()
        image.isTemplate = false
        return image
    }()
}
