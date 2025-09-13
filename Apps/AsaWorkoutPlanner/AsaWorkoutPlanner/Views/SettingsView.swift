//
//  SettingsView.swift
//  AsaWorkoutPlanner
//
//  設定画面
//

import SwiftUI
import AsaUIKit

struct SettingsView: View {
    // MARK: - Properties
    
    @Bindable var viewModel: WorkoutPlannerViewModel
    @AppStorage("weeklyGoal") private var weeklyGoal = 3
    @AppStorage("restTimerSound") private var restTimerSound = true
    @AppStorage("autoProgressiveOverload") private var autoProgressiveOverload = false
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @State private var showingAbout = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // 目標設定
                Section("目標設定") {
                    HStack {
                        Text("週間目標")
                        Spacer()
                        Stepper("\(weeklyGoal)回", value: $weeklyGoal, in: 1...7)
                            .onChange(of: weeklyGoal) { _, newValue in
                                viewModel.weeklyGoal = newValue
                            }
                    }
                }
                
                // ワークアウト設定
                Section("ワークアウト設定") {
                    Toggle("休憩タイマー音", isOn: $restTimerSound)
                    
                    Toggle("自動プログレッシブオーバーロード", isOn: $autoProgressiveOverload)
                    
                    Toggle("リマインダー通知", isOn: $reminderEnabled)
                }
                
                // データ管理
                Section("データ管理") {
                    Button {
                        viewModel.createSamplePlans()
                    } label: {
                        Label("サンプルプランを追加", systemImage: "plus.square")
                    }
                    
                    LabeledContent("総ワークアウト数", value: "\(viewModel.totalWorkouts)")
                    
                    LabeledContent("総運動時間", value: formatDuration(viewModel.totalDuration))
                }
                
                // アプリ情報
                Section("アプリ情報") {
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Text("このアプリについて")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(AsaColors.mutedSage))
                        }
                    }
                    
                    LabeledContent("バージョン", value: "1.0.0")
                    
                    Link(destination: URL(string: "https://asaapps.com")!) {
                        HStack {
                            Text("サポート")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(Color(AsaColors.mutedSage))
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // アプリアイコン
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundColor(Color(AsaColors.coffeeBrown))
                    
                    Text("AsaWorkoutPlanner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("パーソナライズされたワークアウトプランで\nあなたのフィットネス目標を達成")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(Color(AsaColors.mutedSage))
                    
                    // 機能紹介
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "calendar",
                            title: "カスタムプラン作成",
                            description: "自分だけのワークアウトプランを作成"
                        )
                        
                        FeatureRow(
                            icon: "timer",
                            title: "セッション管理",
                            description: "タイマーと進捗トラッキング"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "詳細な統計",
                            description: "パフォーマンスの推移を可視化"
                        )
                        
                        FeatureRow(
                            icon: "heart.fill",
                            title: "健康データ連携",
                            description: "AsaHealthKitとの統合"
                        )
                    }
                    .padding()
                    
                    // クレジット
                    VStack(spacing: 8) {
                        Text("Developed by")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                        
                        Text("朝活パパエンジニア")
                            .font(.headline)
                        
                        Text("© 2024 AsaApps")
                            .font(.caption)
                            .foregroundColor(Color(AsaColors.mutedSage))
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(AsaColors.coffeeBrown))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(AsaColors.mutedSage))
            }
            
            Spacer()
        }
    }
}