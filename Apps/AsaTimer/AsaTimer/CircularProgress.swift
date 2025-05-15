import SwiftUI

struct CircularProgress: Shape {
    var progress: Double // 0.0 〜 1.0

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * progress),
            clockwise: true
        )
        return path
    }
}

#Preview {
    CircularProgress(progress: 0.9)
        .stroke(Color("AsaMocha"), lineWidth: 10)
        .frame(width: 100, height: 100)
}
