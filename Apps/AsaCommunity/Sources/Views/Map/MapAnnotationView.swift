import SwiftUI
import AsaUIKit

/// マップ上のカスタムアノテーション
struct MapAnnotationView: View {
    let iconName: String
    var color: Color = AsaColors.coffeeBrown

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }
            // ポインター三角形
            Triangle()
                .fill(color)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    }
}

/// ポインター用三角形
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
