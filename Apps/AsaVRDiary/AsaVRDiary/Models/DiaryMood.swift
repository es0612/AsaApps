//
//  DiaryMood.swift
//  AsaVRDiary
//
//  日記の感情（気分）定義とVRエフェクトの対応
//

import SwiftUI

/// 日記の感情（気分）
enum DiaryMood: String, CaseIterable, Codable, Sendable {
    case veryHappy = "veryHappy"   // とても嬉しい
    case happy = "happy"           // 嬉しい
    case neutral = "neutral"       // 普通
    case sad = "sad"               // 悲しい
    case verySad = "verySad"       // とても悲しい
    case excited = "excited"       // ワクワク
    case calm = "calm"             // 穏やか
    case anxious = "anxious"       // 不安
    case grateful = "grateful"     // 感謝
    case tired = "tired"           // 疲れた

    // MARK: - Properties

    /// 表示名
    var displayName: String {
        switch self {
        case .veryHappy: return "とても嬉しい"
        case .happy: return "嬉しい"
        case .neutral: return "普通"
        case .sad: return "悲しい"
        case .verySad: return "とても悲しい"
        case .excited: return "ワクワク"
        case .calm: return "穏やか"
        case .anxious: return "不安"
        case .grateful: return "感謝"
        case .tired: return "疲れた"
        }
    }

    /// 絵文字
    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "😊"
        case .neutral: return "😐"
        case .sad: return "😢"
        case .verySad: return "😭"
        case .excited: return "🤩"
        case .calm: return "😌"
        case .anxious: return "😰"
        case .grateful: return "🙏"
        case .tired: return "😴"
        }
    }

    /// 感情の基本カラー
    var color: Color {
        switch self {
        case .veryHappy: return Color(red: 1.0, green: 0.84, blue: 0.0)      // 明るいゴールド
        case .happy: return Color(red: 1.0, green: 0.6, blue: 0.2)           // オレンジ
        case .neutral: return Color(red: 0.6, green: 0.6, blue: 0.6)         // グレー
        case .sad: return Color(red: 0.4, green: 0.5, blue: 0.7)             // 青みがかったグレー
        case .verySad: return Color(red: 0.3, green: 0.3, blue: 0.5)         // 暗い青紫
        case .excited: return Color(red: 1.0, green: 0.4, blue: 0.6)         // ピンク
        case .calm: return Color(red: 0.4, green: 0.7, blue: 0.6)            // 穏やかなグリーン
        case .anxious: return Color(red: 0.7, green: 0.5, blue: 0.7)         // 紫
        case .grateful: return Color(red: 0.9, green: 0.7, blue: 0.5)        // 温かいベージュ
        case .tired: return Color(red: 0.5, green: 0.5, blue: 0.55)          // くすんだグレー
        }
    }

    /// VRエフェクトタイプ
    var vrEffect: VREffect {
        switch self {
        case .veryHappy: return .particles(intensity: 1.0)
        case .happy: return .glow(intensity: 0.8)
        case .neutral: return .none
        case .sad: return .shimmer(intensity: 0.3)
        case .verySad: return .shimmer(intensity: 0.5)
        case .excited: return .pulse(intensity: 1.0)
        case .calm: return .glow(intensity: 0.4)
        case .anxious: return .pulse(intensity: 0.6)
        case .grateful: return .particles(intensity: 0.7)
        case .tired: return .shimmer(intensity: 0.2)
        }
    }

    /// 感情強度（1-5）によるY軸オフセット
    func vrYOffset(intensity: Int) -> Float {
        let baseOffset: Float
        switch self {
        case .veryHappy, .excited, .grateful:
            baseOffset = 0.2
        case .happy, .calm:
            baseOffset = 0.1
        case .neutral:
            baseOffset = 0.0
        case .sad, .anxious, .tired:
            baseOffset = -0.1
        case .verySad:
            baseOffset = -0.2
        }
        return baseOffset * Float(intensity) / 3.0
    }

    /// RealityKitマテリアル用のUIColor
    var uiColor: UIColor {
        UIColor(color)
    }
}

// MARK: - VRエフェクト

/// VR空間での視覚エフェクト
enum VREffect: Equatable, Sendable {
    case none
    case glow(intensity: Float)           // 発光
    case particles(intensity: Float)       // パーティクル
    case pulse(intensity: Float)          // 脈動
    case shimmer(intensity: Float)        // きらめき

    /// エフェクトの強度
    var intensity: Float {
        switch self {
        case .none: return 0
        case .glow(let intensity),
             .particles(let intensity),
             .pulse(let intensity),
             .shimmer(let intensity):
            return intensity
        }
    }

    /// マテリアルの放射率（emissive）
    var emissiveIntensity: Float {
        switch self {
        case .none: return 0
        case .glow(let intensity): return intensity * 0.5
        case .particles(let intensity): return intensity * 0.3
        case .pulse(let intensity): return intensity * 0.6
        case .shimmer(let intensity): return intensity * 0.2
        }
    }

    /// マテリアルの粗さ
    var roughness: Float {
        switch self {
        case .none: return 0.5
        case .glow: return 0.2
        case .particles: return 0.3
        case .pulse: return 0.4
        case .shimmer: return 0.1
        }
    }
}
