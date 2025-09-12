//
//  BaseViewModel.swift
//  AsaCoreKit
//
//  全アプリ共通のベースViewModel
//

import Foundation
import SwiftUI
import Observation

// MARK: - BaseViewModelProtocol

/// 全ViewModel共通のプロトコル
@MainActor
public protocol BaseViewModelProtocol: Observable {
    
    /// エラー状態
    var error: AsaCoreError? { get set }
    
    /// ローディング状態
    var isLoading: Bool { get set }
    
    /// エラー表示用のアラート状態
    var showingErrorAlert: Bool { get set }
    
    /// エラー処理
    func handleError(_ error: Error)
    
    /// ローディング状態更新
    func setLoading(_ loading: Bool)
    
    /// エラー状態クリア
    func clearError()
}

// MARK: - BaseViewModel

/// @Observable対応ベースViewModelクラス
@MainActor
@Observable 
open class BaseViewModel: BaseViewModelProtocol {
    
    // MARK: - Public Properties
    
    /// 現在のエラー状態
    public var error: AsaCoreError?
    
    /// ローディング状態
    public var isLoading: Bool = false
    
    /// エラー表示用のアラート状態
    public var showingErrorAlert: Bool = false
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Error Handling
    
    /// エラーハンドリング
    /// - Parameter error: 発生したエラー
    public func handleError(_ error: Error) {
        if let coreError = error as? AsaCoreError {
            self.error = coreError
        } else {
            self.error = .unknownError(error.localizedDescription)
        }
        showingErrorAlert = true
        setLoading(false)
        
        if AsaCoreKitLib.debugMode {
            print("❌ BaseViewModel Error: \(error)")
        }
    }
    
    /// ローディング状態設定
    /// - Parameter loading: ローディング状態
    public func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    /// エラー状態クリア
    public func clearError() {
        error = nil
        showingErrorAlert = false
    }
    
    // MARK: - Utility Methods
    
    /// 安全な非同期実行（エラー自動ハンドリング）
    /// - Parameter operation: 実行する非同期処理
    public func safeAsync(_ operation: @escaping () async throws -> Void) {
        Task { @MainActor in
            do {
                setLoading(true)
                try await operation()
            } catch {
                handleError(error)
            }
            setLoading(false)
        }
    }
    
    /// 結果を返す安全な非同期実行
    /// - Parameter operation: 実行する非同期処理
    /// - Returns: 処理結果（成功時のみ）
    public func safeAsyncResult<T: Sendable>(_ operation: @escaping () async throws -> T) async -> T? {
        do {
            setLoading(true)
            let result = try await operation()
            setLoading(false)
            return result
        } catch {
            handleError(error)
            setLoading(false)
            return nil
        }
    }
    
    /// バリデーション付きフィールド更新
    /// - Parameters:
    ///   - keyPath: 更新対象のキーパス
    ///   - value: 新しい値
    ///   - validator: バリデーション関数
    public func updateField<T>(
        _ keyPath: ReferenceWritableKeyPath<BaseViewModel, T>,
        to value: T,
        validator: ((T) -> AsaCoreError?)? = nil
    ) {
        if let validator = validator,
           let validationError = validator(value) {
            handleError(validationError)
            return
        }
        
        clearError()
        self[keyPath: keyPath] = value
    }
    
    // MARK: - Lifecycle Methods (Override Points)
    
    /// 初期化処理（サブクラスでオーバーライド）
    open func initialize() {
        // サブクラスで実装
    }
    
    /// データ読み込み処理（サブクラスでオーバーライド）
    open func loadData() async throws {
        // サブクラスで実装
    }
    
    /// データ保存処理（サブクラスでオーバーライド）
    open func saveData() async throws {
        // サブクラスで実装
    }
    
    /// リフレッシュ処理（サブクラスでオーバーライド）
    open func refresh() {
        safeAsync {
            try await self.loadData()
        }
    }
}