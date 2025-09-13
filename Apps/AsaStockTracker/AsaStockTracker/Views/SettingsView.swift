//
//  SettingsView.swift
//  AsaStockTracker
//
//  Created by Asa Apps on 2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(WatchListViewModel.self) private var watchListViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("updateInterval") private var updateInterval = Constants.UpdateInterval.standard
    @AppStorage("showNotifications") private var showNotifications = false
    @AppStorage("useDemoMode") private var useDemoMode = true
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                // データ設定
                Section("データ設定") {
                    Toggle("デモモードを使用", isOn: $useDemoMode)
                        .tint(Color(red: 0.776, green: 0.549, blue: 0.325))  // AsaCoffeeBrown
                    
                    Text("デモモードでは、実際のAPIを使用せずにサンプルデータを表示します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("更新間隔", selection: $updateInterval) {
                        Text("30秒").tag(Constants.UpdateInterval.realtime)
                        Text("1分").tag(Constants.UpdateInterval.standard)
                        Text("5分").tag(Constants.UpdateInterval.background)
                    }
                }
                
                // 通知設定
                Section("通知設定") {
                    Toggle("価格アラートを有効化", isOn: $showNotifications)
                        .tint(Color(red: 0.776, green: 0.549, blue: 0.325))  // AsaCoffeeBrown
                    
                    if showNotifications {
                        Text("価格が設定した閾値を超えた場合に通知します")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // ウォッチリスト管理
                Section("ウォッチリスト") {
                    HStack {
                        Text("登録銘柄数")
                        Spacer()
                        Text("\(watchListViewModel.watchListCount) / \(Constants.UI.maxStocksInWatchlist)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("お気に入り数")
                        Spacer()
                        Text("\(watchListViewModel.favoriteSymbols.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Text("ウォッチリストをクリア")
                    }
                }
                
                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("開発者")
                        Spacer()
                        Text("Asa Apps")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://www.alphavantage.co")!) {
                        HStack {
                            Text("Alpha Vantage API")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                }
                
                // デバッグ設定（開発用）
                Section("デバッグ") {
                    Button("サンプルデータを再読み込み") {
                        watchListViewModel.loadDemoData()
                        dismiss()
                    }
                    
                    Button("キャッシュをクリア") {
                        NetworkManager.shared.clearCache()
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("ウォッチリストをクリア", isPresented: $showingClearConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("クリア", role: .destructive) {
                    clearWatchList()
                }
            } message: {
                Text("ウォッチリストのすべての銘柄が削除されます。この操作は取り消せません。")
            }
        }
    }
    
    private func clearWatchList() {
        watchListViewModel.watchList = WatchList()
        watchListViewModel.favoriteSymbols = []
        watchListViewModel.watchList.save()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environment(WatchListViewModel())
}