// AsaApps/Apps/AsaBookTracker/Views/SettingsView.swift
import SwiftUI
import AsaUIKit

/// アプリの設定画面
struct SettingsView: View {
    @Bindable var viewModel: BookTrackerViewModel
    @State private var showingDataExport = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // アプリ情報セクション
                appInfoSection
                
                // データ管理セクション
                dataManagementSection
                
                // 表示設定セクション
                displaySettingsSection
                
                // アバウトセクション
                aboutSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .background(AsaColors.softCream.opacity(0.1))
        }
        .alert("全データ削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteAllData()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("すべての本と読書記録が削除されます。この操作は取り消せません。")
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var appInfoSection: some View {
        Section {
            HStack {
                Image(systemName: "books.vertical")
                    .font(.title2)
                    .foregroundColor(AsaColors.coffeeBrown)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AsaBookTracker")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    Text("読書進捗管理アプリ")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
                
                Spacer()
                
                Text("v1.0.0")
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate)
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var dataManagementSection: some View {
        Section(header: Text("データ管理").foregroundColor(AsaColors.coffeeBrown)) {
            // 統計概要
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(AsaColors.mutedSage)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("データ概要")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Text("本: \(viewModel.books.count)冊, セッション: \(totalSessions)回")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            // データ更新
            Button(action: {
                viewModel.refreshData()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AsaColors.coffeeBrown)
                        .frame(width: 24)
                    
                    Text("データを更新")
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 4)
            
            #if DEBUG
            // サンプルデータ読込（デバッグ専用）
            Button(action: {
                viewModel.loadSampleData()
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .foregroundColor(AsaColors.coffeeBrown)
                        .frame(width: 24)

                    Text("サンプルデータ読込")
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    Text("10冊")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding(.vertical, 4)
            #endif

            // データエクスポート（将来の機能）
            Button(action: {
                showingDataExport = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AsaColors.coffeeBrown)
                        .frame(width: 24)

                    Text("データをエクスポート")
                        .foregroundColor(AsaColors.darkSlate)

                    Spacer()

                    Text("CSV")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding(.vertical, 4)
            
            // 全データ削除
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("全データを削除")
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var displaySettingsSection: some View {
        Section(header: Text("表示設定").foregroundColor(AsaColors.coffeeBrown)) {
            // ソート設定
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(AsaColors.mutedSage)
                    .frame(width: 24)
                
                Text("デフォルトソート")
                    .foregroundColor(AsaColors.darkSlate)
                
                Spacer()
                
                Picker("", selection: .constant(viewModel.sortOption)) {
                    ForEach(BookSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(AsaColors.coffeeBrown)
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var aboutSection: some View {
        Section(header: Text("アプリについて").foregroundColor(AsaColors.coffeeBrown)) {
            // フィードバック
            Button(action: {
                // フィードバック機能（将来実装）
            }) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(AsaColors.coffeeBrown)
                        .frame(width: 24)
                    
                    Text("フィードバックを送信")
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding(.vertical, 4)
            
            // レビュー
            Button(action: {
                // アプリストアレビュー（将来実装）
            }) {
                HStack {
                    Image(systemName: "star")
                        .foregroundColor(AsaColors.coffeeBrown)
                        .frame(width: 24)
                    
                    Text("App Storeでレビュー")
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding(.vertical, 4)
            
            // 開発者情報
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(AsaColors.mutedSage)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("開発者")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Text("AsaApps - 朝活パパエンジニア")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            // ライセンス
            Button(action: {
                // ライセンス情報（将来実装）
            }) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(AsaColors.coffeeBrown)
                        .frame(width: 24)
                    
                    Text("ライセンス情報")
                        .foregroundColor(AsaColors.darkSlate)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalSessions: Int {
        viewModel.books.flatMap { $0.sessions }.count
    }
    
    // MARK: - Methods
    
    private func deleteAllData() {
        // 全ての本を削除
        for book in viewModel.books {
            viewModel.deleteBook(book)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(viewModel: BookTrackerViewModel())
}