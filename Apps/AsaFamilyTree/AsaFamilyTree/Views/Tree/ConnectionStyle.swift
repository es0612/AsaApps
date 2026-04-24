import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

/// `ConnectionType` を SwiftUI の描画プリミティブへ写すヘルパー群
extension ConnectionType {
    /// SwiftUI Color へ変換
    var swiftUIColor: Color {
        Color(cgColor: lineColor)
    }

    /// 描画時のストロークスタイル
    func strokeStyle() -> StrokeStyle {
        StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: isDashed ? [6, 4] : []
        )
    }

    /// 凡例に表示する日本語ラベル
    var legendLabel: String {
        switch self {
        case .parentChild: return "親子"
        case .currentSpouse: return "配偶者"
        case .divorcedSpouse: return "離別配偶者"
        case .siblingBus: return "兄弟姉妹"
        }
    }
}
