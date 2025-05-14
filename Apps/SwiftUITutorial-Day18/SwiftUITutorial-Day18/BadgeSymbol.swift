import SwiftUI

struct BadgeSymbol: Shape {
    static let symbolColor = Color(red: 79.0 / 255, green: 79.0 / 255, blue: 191.0 / 255)

    func path(in rect: CGRect) -> Path {
        let width = min(rect.size.width, rect.size.height)
        let height = width
        let spacing = width * 0.030
        let middle = width / 2
        let topWidth = width * 0.226
        let topHeight = height * 0.488

        var path = Path()
        path.move(to: CGPoint(x: middle, y: spacing))
        path.addLine(to: CGPoint(x: middle - topWidth, y: topHeight - spacing))
        path.addLine(to: CGPoint(x: middle, y: topHeight / 2 + spacing))
        path.addLine(to: CGPoint(x: middle + topWidth, y: topHeight - spacing))
        path.addLine(to: CGPoint(x: middle, y: spacing))

        let bottomWidth = width * 0.160
        let bottomHeight = height * 0.696
        path.move(to: CGPoint(x: middle, y: topHeight / 2 + spacing * 2))
        path.addLine(to: CGPoint(x: middle - bottomWidth, y: bottomHeight - spacing))
        path.addLine(to: CGPoint(x: middle, y: bottomHeight - spacing))
        path.addLine(to: CGPoint(x: middle + bottomWidth, y: bottomHeight - spacing))
        path.addLine(to: CGPoint(x: middle, y: topHeight / 2 + spacing * 2))

        return path
    }
}

#Preview {
    BadgeSymbol()
        .fill(BadgeSymbol.symbolColor)
        .frame(width: 100, height: 100)
}
