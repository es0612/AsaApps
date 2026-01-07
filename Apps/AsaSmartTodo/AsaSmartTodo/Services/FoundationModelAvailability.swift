//
//  FoundationModelAvailability.swift
//  AsaSmartTodo
//
//  iOS 18 Foundation Modelsの可用性チェックユーティリティ
//  iOS 17以下との互換性を保ちながら、iOS 18のLLM機能を安全に利用
//

import Foundation

#if canImport(LanguageModel)
import LanguageModel
#endif

/// Foundation Modelsの可用性状態
enum FoundationModelStatus {
    case available              // iOS 18+で利用可能
    case unavailable(reason: UnavailabilityReason)  // 利用不可

    enum UnavailabilityReason {
        case olderOS               // iOS 17以下
        case modelNotAvailable     // モデルが利用不可
        case unknown               // 不明なエラー
    }
}

/// iOS 18 Foundation Modelsの可用性をチェックするクラス
@MainActor
class FoundationModelAvailability {

    // MARK: - Singleton

    static let shared = FoundationModelAvailability()

    init() {}

    // MARK: - Availability Check

    /// Foundation Modelsが利用可能かどうかを確認
    ///
    /// iOS 18以降で、かつSystemLanguageModelが利用可能な場合にtrueを返します。
    /// iOS 17以下では常にfalseを返します。
    ///
    /// - Returns: Foundation Modelsが利用可能ならtrue
    func isAvailable() async -> Bool {
        #if canImport(LanguageModel)
        if #available(iOS 18.0, *) {
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                return true
            case .unavailable:
                return false
            }
        }
        #endif
        return false
    }

    /// Foundation Modelsの詳細な状態を取得
    ///
    /// デバッグや設定画面での表示に使用できる詳細な状態情報を返します。
    ///
    /// - Returns: FoundationModelStatus（利用可能または理由付きの利用不可）
    func getStatus() async -> FoundationModelStatus {
        #if canImport(LanguageModel)
        if #available(iOS 18.0, *) {
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                return .available
            case .unavailable(let reason):
                // SystemLanguageModelのUnavailabilityReasonを解析
                print("Foundation Models利用不可: \(reason)")
                return .unavailable(reason: .modelNotAvailable)
            }
        } else {
            return .unavailable(reason: .olderOS)
        }
        #else
        return .unavailable(reason: .olderOS)
        #endif
    }

    /// ユーザー向けの可用性メッセージを取得
    ///
    /// 設定画面などで表示するための、わかりやすい日本語メッセージを返します。
    ///
    /// - Returns: ユーザー向けメッセージ文字列
    func getUserFacingMessage() async -> String {
        let status = await getStatus()

        switch status {
        case .available:
            return "✨ iOS 18の高度なAI分析が利用可能です"
        case .unavailable(let reason):
            switch reason {
            case .olderOS:
                return "iOS 18以降で高度なAI分析が利用可能になります"
            case .modelNotAvailable:
                return "AI分析モデルが現在利用できません"
            case .unknown:
                return "AI分析が現在利用できません"
            }
        }
    }

    /// デバッグ用の詳細情報を取得
    ///
    /// - Returns: デバッグ情報の辞書
    func getDebugInfo() async -> [String: Any] {
        var info: [String: Any] = [:]

        // iOS バージョン
        if #available(iOS 18.0, *) {
            info["iOS Version"] = "18.0+"
        } else {
            info["iOS Version"] = "< 18.0"
        }

        // LanguageModel フレームワーク可用性
        #if canImport(LanguageModel)
        info["LanguageModel Framework"] = "Available"

        if #available(iOS 18.0, *) {
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                info["SystemLanguageModel"] = "Available"
            case .unavailable(let reason):
                info["SystemLanguageModel"] = "Unavailable: \(reason)"
            }
        }
        #else
        info["LanguageModel Framework"] = "Not Available"
        #endif

        return info
    }
}
