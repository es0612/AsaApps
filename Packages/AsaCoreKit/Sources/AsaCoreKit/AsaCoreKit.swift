//
//  AsaCoreKit.swift
//  AsaCoreKit
//
//  共通基盤ライブラリのメインインターフェース
//

import Foundation
import SwiftUI
import Observation

// MARK: - AsaCoreKit Main

/// AsaCoreKit - AsaApps共通基盤ライブラリ
/// 
/// 全アプリで共通利用する以下の機能を提供：
/// - @Observable対応BaseViewModel
/// - UserDefaults + JSON永続化
/// - フォーム入力検証
/// - 標準CRUD操作
/// - 統一エラーハンドリング
public struct AsaCoreKitLib {
    
    /// ライブラリバージョン
    public static let version = "1.0.0"
    
    /// デバッグモード設定
    nonisolated(unsafe) public static var debugMode: Bool = false
    
    private init() {}
}