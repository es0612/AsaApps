//
//  ViewModelSupport.swift  
//  AsaCoreKit
//
//  BaseViewModel用のSwiftUIサポート
//

import Foundation
import SwiftUI

// MARK: - View Extensions

extension View {
    
    /// BaseViewModelのエラーアラートを自動表示
    /// - Parameter viewModel: BaseViewModelProtocol準拠のViewModel
    /// - Returns: エラーアラート付きView
    @MainActor
    public func errorAlert<VM: BaseViewModelProtocol>(
        viewModel: VM
    ) -> some View {
        self.alert(
            "エラー",
            isPresented: Binding(
                get: { viewModel.showingErrorAlert },
                set: { _ in viewModel.clearError() }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "不明なエラーが発生しました")
        }
    }
    
    /// BaseViewModelのローディング状態表示
    /// - Parameter viewModel: BaseViewModelProtocol準拠のViewModel
    /// - Returns: ローディングオーバーレイ付きView
    @MainActor
    public func loadingOverlay<VM: BaseViewModelProtocol>(
        viewModel: VM
    ) -> some View {
        self.overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("読み込み中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    /// BaseViewModelの完全サポート（エラーアラート＋ローディング）
    /// - Parameter viewModel: BaseViewModelProtocol準拠のViewModel
    /// - Returns: 完全サポート付きView
    @MainActor
    public func viewModelSupport<VM: BaseViewModelProtocol>(
        _ viewModel: VM
    ) -> some View {
        self
            .errorAlert(viewModel: viewModel)
            .loadingOverlay(viewModel: viewModel)
    }
}

// MARK: - BaseViewModel Binding Extensions

extension BaseViewModel {
    
    /// String型フィールドのBinding作成
    /// - Parameters:
    ///   - keyPath: 対象のキーパス
    ///   - validator: バリデーション関数（オプション）
    /// - Returns: Binding<String>
    public func binding<T>(
        for keyPath: ReferenceWritableKeyPath<BaseViewModel, T>,
        validator: ((T) -> AsaCoreError?)? = nil
    ) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { newValue in
                self.updateField(keyPath, to: newValue, validator: validator)
            }
        )
    }
}

// MARK: - Task Extensions for BaseViewModel

extension BaseViewModel {
    
    /// ViewDidLoad相当の処理を実行
    public func onAppear() {
        if !isLoading {
            initialize()
            refresh()
        }
    }
    
    /// 定期的なデータ更新タスク開始
    /// - Parameter interval: 更新間隔（秒）
    /// - Returns: Taskハンドル
    @discardableResult
    public func startPeriodicRefresh(interval: TimeInterval = 60.0) -> Task<Void, Never> {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                
                if !Task.isCancelled {
                    await MainActor.run {
                        refresh()
                    }
                }
            }
        }
    }
}