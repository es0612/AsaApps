import SwiftUI

/// AsaAppsブランドカラー定義
public struct AsaColors {
    
    /// プライマリカラー - ボタンやテキストのメインカラー
    public static let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325) // #C68C53
    
    /// セカンダリカラー - 背景やアクセント
    public static let mocha = Color(red: 0.545, green: 0.353, blue: 0.169) // #8B5A2B
    
    /// ハイライトカラー - 選択状態や強調表示
    public static let softCream = Color(red: 0.910, green: 0.835, blue: 0.725) // #E8D5B9
    
    /// ニュートラルカラー - 背景用
    public static let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275) // #2F3E46
    
    /// アクセントカラー - 微細な要素用
    public static let mutedSage = Color(red: 0.478, green: 0.569, blue: 0.553) // #7A918D
    
    /// カード背景色 - 半透明の白色
    public static let cardBackground = Color.white.opacity(0.8)
    
    /// Kanban専用カラー
    public static let todoColumn = softCream
    public static let inProgressColumn = mutedSage
    public static let doneColumn = coffeeBrown.opacity(0.3)
}