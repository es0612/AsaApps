//
//  SettingsView.swift
//  AsaSleepLog
//  
//  Created on 2025/06/26
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SleepLogViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearDataAlert = false
    @State private var showingSampleDataAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // データ管理セクション
                Section("データ管理") {
                    Button(action: {
                        showingSampleDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("サンプルデータを追加")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                    
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("全データを削除")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // アプリ情報セクション
                Section("アプリ情報") {
                    HStack {
                        Text("現在の記録数")
                        Spacer()
                        Text("\(viewModel.sleepLogs.count)件")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("最新記録")
                        Spacer()
                        if let latestLog = viewModel.sleepLogs.first {
                            Text(latestLog.date, style: .date)
                                .foregroundColor(.gray)
                        } else {
                            Text("なし")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text("平均睡眠効率")
                        Spacer()
                        Text(String(format: "%.1f%%", viewModel.averageSleepEfficiency))
                            .foregroundColor(.gray)
                    }
                }
                
                // 使い方セクション
                Section("使い方") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("記録の編集")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("記録をタップすると編集できます")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("記録の削除")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("記録を左にスワイプすると削除できます")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("睡眠効率について")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("睡眠効率 = (実際の睡眠時間 ÷ ベッドにいた時間) × 100")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("85%以上が理想的です")
                            .font(.caption)
                            .foregroundColor(.gray)
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
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            .alert("サンプルデータを追加", isPresented: $showingSampleDataAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("追加") {
                    viewModel.generateSampleData()
                }
            } message: {
                Text("過去14日分のサンプルデータを生成します。グラフなどの動作確認に使用できます。")
            }
            .alert("全データを削除", isPresented: $showingClearDataAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    viewModel.clearAllData()
                }
            } message: {
                Text("すべての睡眠記録が削除されます。この操作は取り消せません。")
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: SleepLogViewModel())
}