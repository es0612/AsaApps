import SwiftUI

struct Badge: View {
    private static let rotationCount = 8

    var badgeSymbols: some View {
        ForEach(0..<Self.rotationCount) { i in
            RotatedBadgeSymbol(angle: .degrees(Double(i) / Double(Self.rotationCount)) * 360.0)
                .opacity(0.5)
        }
    }

    var body: some View {
        ZStack {
            BadgeBackground()
            GeometryReader { geometry in
                badgeSymbols
                    .scaleEffect(1.0 / 4.0, anchor: .top)
                    .position(x: geometry.size.width / 2.0, y: (3.0 / 4.0) * geometry.size.height)
            }
        }
        .scaledToFit()
    }
}

struct RotatedBadgeSymbol: View {
    let angle: Angle

    var body: some View {
        BadgeSymbol()
            .fill(BadgeSymbol.symbolColor)
            .frame(width: 100, height: 100)
            .rotationEffect(angle, anchor: .bottom)
    }
}

#Preview {
    Badge()
}
