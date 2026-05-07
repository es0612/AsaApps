import SwiftUI

// MARK: - Hub カードスタイル

/// AsaPapaHub 内のカード状コンテナで使う共通スタイル。
/// 角丸・パディング・シャドウを 1 か所に集約し、画面間のトーンを揃える。
extension View {
    /// 標準カード（DomainSummaryCard、ドメイン詳細セクション、ホームの補助カード）
    func hubCardStyle(cornerRadius: CGFloat = 14, padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
    }

    /// 主役カード（朝活スコアカード、ブリーフィング、ScoreRing 中心の表示など）
    /// 標準カードよりやや強めのシャドウで階層を表現
    func hubFeaturedCardStyle(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
    }
}
