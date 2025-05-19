import SwiftUI
import UIKit

struct CustomCircularProgress: UIViewRepresentable {
    var progress: Double // プログレスの値（0.0〜1.0）
    var lineWidth: CGFloat = 10.0 // 線の太さ
    var trackColor: UIColor = UIColor.lightGray // 背景の円の色
    var progressColor: UIColor = UIColor(named: "AsaMocha") ?? .brown // プログレスの色

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        // 円形パスを作成
        let shapeLayer = CAShapeLayer()
        let progressLayer = CAShapeLayer()
        
        // ビューの中心と半径を設定
        let center = CGPoint(x: 60, y: 60) // 仮のサイズ（後で調整）
        let radius = (min(120, 120) - lineWidth) / 2
        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: 1.5 * CGFloat.pi,
            clockwise: true
        )
        
        // 背景の円（トラック）
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = trackColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        view.layer.addSublayer(shapeLayer)
        
        // プログレスの円
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0 // 初期値（プログレス0）
        view.layer.addSublayer(progressLayer)
        
        // プログレスレイヤーをコンテキストに保存
        context.coordinator.progressLayer = progressLayer
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // プログレスを更新
        context.coordinator.progressLayer?.strokeEnd = CGFloat(progress)
        
        // アニメーションを追加
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 1.0
        animation.fromValue = context.coordinator.previousProgress
        animation.toValue = progress
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        context.coordinator.progressLayer?.add(animation, forKey: "progressAnimation")
        
        // 現在のプログレスを保存
        context.coordinator.previousProgress = progress
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var progressLayer: CAShapeLayer?
        var previousProgress: Double = 0
    }
}
