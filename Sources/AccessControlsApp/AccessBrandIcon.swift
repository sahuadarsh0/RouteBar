import SwiftUI

struct AccessBrandIcon: View {
    var size: CGFloat = 22
    var showsShadow = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FFE58E"),
                            Color(hex: "#FF9D52"),
                            Color(hex: "#FF5E73")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.42), .clear],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: size * 0.82
                    )
                )

            AccessRouteGlyph()
                .stroke(
                    Color(hex: "#07100D"),
                    style: StrokeStyle(
                        lineWidth: max(2.4, size * 0.12),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: size * 0.58, height: size * 0.48)
                .offset(x: size * 0.01, y: size * 0.01)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(showsShadow ? 0.28 : 0), radius: size * 0.18, y: size * 0.09)
        .accessibilityHidden(true)
    }
}

private struct AccessRouteGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let start = CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.70)
        let firstPeak = CGPoint(x: rect.minX + rect.width * 0.31, y: rect.minY + rect.height * 0.36)
        let valley = CGPoint(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.59)
        let arrowTip = CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.12)
        let arrowLeft = CGPoint(x: rect.minX + rect.width * 0.64, y: rect.minY + rect.height * 0.12)
        let arrowDown = CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.42)

        path.move(to: start)
        path.addLine(to: firstPeak)
        path.addLine(to: valley)
        path.addLine(to: arrowTip)

        path.move(to: arrowLeft)
        path.addLine(to: arrowTip)
        path.addLine(to: arrowDown)

        return path
    }
}
