import SwiftUI

public extension View {
    /// Asaスタイルのカードスタイルを適用
    func asaCardStyle() -> some View {
        self
            .padding()
            .background(AsaColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(radius: 2)
    }
    
    /// Kanbanカラムのスタイルを適用
    func kanbanColumnStyle(backgroundColor: Color = AsaColors.softCream.opacity(0.3)) -> some View {
        self
            .padding()
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    /// ドラッグ可能なカードスタイル
    func draggableCardStyle(isDragging: Bool = false) -> some View {
        self
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .opacity(isDragging ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
    }
}