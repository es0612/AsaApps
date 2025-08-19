//
//  ContentView.swift
//  AsaSleepAnalyzer
//  
//  Created on 2025/08/05
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SleepAnalyzerViewModel()
    @State private var showingStatsView = false
    @State private var showingDetailsView = false
    @State private var showingDebugInfo = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("AsaSoftCream").edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView("データを読み込み中...")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // 権限要求セクション
                            if !viewModel.isHealthKitAuthorized {
                                permissionSection
                            }
                            
                            // 今日の睡眠サマリー
                            if let todayData = viewModel.todaySleepData {
                                todaySleepSummary(todayData)
                            } else if viewModel.isHealthKitAuthorized {
                                noDataView
                            }
                            
                            // 週間睡眠進捗
                            if viewModel.isHealthKitAuthorized && !viewModel.weeklySleepData.isEmpty {
                                weeklySleepProgress
                            }
                            
                            // クイック統計
                            if viewModel.isHealthKitAuthorized {
                                quickStatsSection
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("睡眠分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isHealthKitAuthorized {
                        Button(action: {
                            Task {
                                await viewModel.refreshAllData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !viewModel.isHealthKitAuthorized {
                            Button(action: {
                                Task {
                                    await viewModel.forcePermissionCheck()
                                }
                            }) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Button(action: {
                            showingDebugInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                        
                        if viewModel.isHealthKitAuthorized {
                            Button(action: {
                                showingStatsView = true
                            }) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                    }
                }
            }
            .alert("HealthKit権限エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("睡眠データへのアクセス", isPresented: $viewModel.showingPermissionAlert) {
                Button("許可する") {
                    Task {
                        await viewModel.requestHealthKitPermission()
                    }
                }
                Button("後で", role: .cancel) {
                    viewModel.showingPermissionAlert = false
                }
            } message: {
                Text("睡眠データを分析するために、HealthKitへのアクセスを許可してください。")
            }
            .sheet(isPresented: $showingStatsView) {
                SleepStatsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingDetailsView) {
                if let todayData = viewModel.todaySleepData {
                    SleepDetailsView(sleepData: todayData, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingDebugInfo) {
                DebugInfoView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.loadSleepGoal()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                await viewModel.handleAppDidBecomeActive()
            }
        }
        .accentColor(Color("AsaCoffeeBrown"))
    }
    
    // MARK: - 権限要求セクション
    
    private var permissionSection: some View {
        AsaCard {
            VStack(spacing: 16) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("睡眠データ分析")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text(viewModel.authorizationStatusDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if !viewModel.isHealthKitAuthorized {
                    VStack(spacing: 8) {
                        Text("📱 設定アプリ > プライバシーとセキュリティ > ヘルスケア > AsaSleepAnalyzer > 睡眠をONにしてください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("権限状態を再確認") {
                            Task {
                                await viewModel.forcePermissionCheck()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                    }
                }
                
                if !viewModel.isHealthKitAuthorized {
                    AsaButton(
                        title: "HealthKitアクセスを許可",
                        action: {
                            Task {
                                await viewModel.requestHealthKitPermission()
                            }
                        },
                        color: Color("AsaCoffeeBrown")
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - 今日の睡眠サマリー
    
    private func todaySleepSummary(_ sleepData: SleepData) -> some View {
        AsaCard {
            VStack(spacing: 20) {
                // 睡眠品質インジケーター
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.2)
                        .foregroundColor(Color("AsaMocha"))
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(viewModel.todaySleepProgress, 1.0)))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.spring(), value: viewModel.todaySleepProgress)
                    
                    VStack {
                        Text(sleepData.formattedTotalSleepDuration)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("睡眠時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: sleepData.qualityLevel.systemImageName)
                                .foregroundColor(Color(sleepData.qualityLevel.color))
                            Text(sleepData.qualityLevel.rawValue)
                                .font(.caption)
                                .foregroundColor(Color(sleepData.qualityLevel.color))
                        }
                    }
                }
                .frame(width: 180, height: 180)
                
                // 詳細情報
                HStack(spacing: 30) {
                    VStack {
                        Text("就寝")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(sleepData.formattedBedtime)
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                    
                    VStack {
                        Text("起床")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(sleepData.formattedWakeTime)
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                    
                    VStack {
                        Text("効率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(sleepData.formattedSleepEfficiency)
                            .font(.headline)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                // 詳細表示ボタン
                AsaButton(
                    title: "詳細を見る",
                    action: {
                        showingDetailsView = true
                    },
                    color: Color("AsaMutedSage")
                )
            }
            .padding()
        }
    }
    
    // MARK: - データなし表示
    
    private var noDataView: some View {
        AsaCard {
            VStack(spacing: 16) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 50))
                    .foregroundColor(Color("AsaMutedSage"))
                
                Text("今日の睡眠データなし")
                    .font(.headline)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("睡眠データが記録されていません。HealthアプリやApple Watchで睡眠を記録してください。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                AsaButton(
                    title: "データを更新",
                    action: {
                        Task {
                            await viewModel.refreshAllData()
                        }
                    },
                    color: Color("AsaCoffeeBrown")
                )
            }
            .padding()
        }
    }
    
    // MARK: - 週間睡眠進捗
    
    private var weeklySleepProgress: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("週間睡眠パターン")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Text("平均: \(viewModel.formatDuration(viewModel.averageSleepDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    ForEach(viewModel.weeklySleepData, id: \.date) { sleepData in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color("AsaCoffeeBrown"))
                                .frame(width: 30, height: max(4, CGFloat(sleepData.totalSleepDuration / 3600) * 8))
                                .animation(.easeInOut, value: sleepData.totalSleepDuration)
                            
                            Text(dayOfWeek(from: sleepData.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
        }
    }
    
    // MARK: - クイック統計セクション
    
    private var quickStatsSection: some View {
        HStack(spacing: 15) {
            quickStatCard(
                title: "平均品質",
                value: viewModel.formatScore(viewModel.averageQualityScore),
                icon: "star.fill",
                color: Color("AsaCoffeeBrown")
            )
            
            quickStatCard(
                title: "平均効率",
                value: viewModel.formatEfficiency(viewModel.averageSleepEfficiency),
                icon: "gauge.medium",
                color: Color("AsaMutedSage")
            )
        }
    }
    
    private func quickStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        AsaCard {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Debug Info View
struct DebugInfoView: View {
    let viewModel: SleepAnalyzerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 権限状態セクション
                    VStack(alignment: .leading, spacing: 8) {
                        Text("現在の権限状態")
                            .font(.headline)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("HealthKit利用可能:")
                                Spacer()
                                Image(systemName: viewModel.isHealthKitAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(viewModel.isHealthKitAuthorized ? .green : .red)
                            }
                            
                            Text("状態: \(viewModel.authorizationStatusDescription)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // デバッグログセクション
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("デバッグログ")
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Spacer()
                            
                            Button("クリア") {
                                viewModel.clearDebugInfo()
                            }
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                        }
                        
                        ScrollView {
                            Text(viewModel.debugInfo.isEmpty ? "ログがありません" : viewModel.debugInfo)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .frame(height: 300)
                    }
                    
                    // アクションセクション
                    VStack(spacing: 12) {
                        AsaButton(
                            title: "権限状態を強制更新",
                            action: {
                                Task {
                                    await viewModel.forcePermissionCheck()
                                }
                            },
                            color: Color("AsaCoffeeBrown")
                        )
                        
                        if !viewModel.isHealthKitAuthorized {
                            AsaButton(
                                title: "設定アプリを開く",
                                action: {
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                },
                                color: Color("AsaMutedSage")
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("デバッグ情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SleepData.self, inMemory: true)
}
