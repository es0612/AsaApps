import Foundation

// MARK: - InsightGenerating

/// 金融インサイト生成プロトコル
public protocol InsightGenerating: Sendable {
    /// プランとユーザー設定に基づいてインサイトを生成
    /// - Parameters:
    ///   - plan: 分析対象の金融プラン
    ///   - settings: ユーザー設定
    /// - Returns: 生成されたインサイトの配列
    func generateInsights(
        plan: FinancialPlan,
        settings: UserSettings
    ) -> [FinancialInsight]
}
