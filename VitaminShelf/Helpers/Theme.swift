import SwiftUI

struct Theme {
    static let bg = Color(red: 0.05, green: 0.04, blue: 0.10)
    static let surface = Color(red: 0.08, green: 0.07, blue: 0.16)
    static let card = Color(red: 0.11, green: 0.10, blue: 0.20)
    static let accent = Color(red: 0.96, green: 0.65, blue: 0.14)
    static let secondary = Color(red: 0.60, green: 0.45, blue: 0.95)
    static let warm = Color(red: 0.95, green: 0.55, blue: 0.20)
    static let danger = Color(red: 0.95, green: 0.30, blue: 0.30)
    static let info = Color(red: 0.35, green: 0.65, blue: 0.98)
    static let success = Color(red: 0.25, green: 0.82, blue: 0.48)
    static let text = Color(red: 0.95, green: 0.94, blue: 0.97)
    static let sub = Color(red: 0.50, green: 0.52, blue: 0.65)
    static let muted = Color(red: 0.25, green: 0.26, blue: 0.34)
}

struct GlowCard: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content.padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(color))
            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    }
}

extension View {
    func glowCard(_ color: Color = Theme.card) -> some View { modifier(GlowCard(color: color)) }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 10
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle().trim(from: 0, to: min(max(progress, 0), 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct PillBar: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2).fill(color.opacity(0.15)).frame(height: height)
                RoundedRectangle(cornerRadius: height / 2).fill(color)
                    .frame(width: max(geo.size.width * min(max(progress, 0), 1.0), 2), height: height)
                    .animation(.easeOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: height)
    }
}
