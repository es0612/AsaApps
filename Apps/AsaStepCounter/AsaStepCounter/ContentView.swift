//
//  ContentView.swift
//  AsaStepCounter
//  
//  Created on 2025/08/15
//

import SwiftUI
import SwiftData
import HealthKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StepCountService.self) private var stepCountService
    @Query private var stepRecords: [StepRecord]
    
    @State private var showingGoalSetting = false
    @State private var showingHistory = false
    
    // 今日のStepRecordを取得または作成
    private var todayRecord: StepRecord {
        let today = Calendar.current.startOfDay(for: Date())
        if let record = stepRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return record
        } else {
            let newRecord = StepRecord(date: today)
            modelContext.insert(newRecord)
            return newRecord
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color("AsaSoftCream"), Color("AsaDarkSlate").opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // HealthKit権限状態
                        if !stepCountService.isAuthorized {
                            healthKitPermissionCard
                        }
                        
                        // メイン歩数表示カード
                        mainStepCountCard
                        
                        // 統計とナビゲーション
                        statisticsAndNavigationSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("朝歩数カウンター")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("設定") {
                        showingGoalSetting = true
                    }
                }
            }
            .sheet(isPresented: $showingGoalSetting) {
                GoalSettingView(stepRecord: todayRecord)
            }
            .sheet(isPresented: $showingHistory) {
                StepHistoryView()
            }
            .task {
                if stepCountService.isAuthorized {
                    await refreshData()
                }
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - HealthKit権限カード
    private var healthKitPermissionCard: some View {
        AsaCard {
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("HealthKitへのアクセス")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text(stepCountService.authorizationStatusDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if !stepCountService.hasRequestedPermission || stepCountService.authorizationStatus == .notDetermined {
                    AsaButton(
                        title: "権限を許可",
                        action: {
                            Task {
                                await stepCountService.requestAuthorization()
                            }
                        },
                        color: Color("AsaCoffeeBrown")
                    )
                }
            }
        }
    }
    
    // MARK: - メイン歩数カード
    private var mainStepCountCard: some View {
        AsaCard {
            VStack(spacing: 20) {
                // 今日の日付
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.headline)
                    .foregroundColor(Color("AsaMutedSage"))
                
                // 円形プログレス付き歩数表示
                ZStack {
                    // 背景円
                    Circle()
                        .stroke(Color("AsaSoftCream"), lineWidth: 12)
                        .frame(width: 160, height: 160)
                    
                    // プログレス円
                    Circle()
                        .trim(from: 0, to: min(todayRecord.achievementRate, 1.0))
                        .stroke(
                            Color("AsaCoffeeBrown"),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: todayRecord.achievementRate)
                    
                    // 中央の歩数表示
                    VStack(spacing: 4) {
                        Text("\(stepCountService.todayStepCount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .contentTransition(.numericText())
                            .animation(.bouncy(duration: 0.5), value: stepCountService.todayStepCount)
                        
                        Text("歩")
                            .font(.headline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Divider()
                            .frame(width: 60)
                            .background(Color("AsaMutedSage"))
                        
                        Text("目標 \(todayRecord.dailyGoal)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 目標達成時のエフェクト
                    if todayRecord.isGoalAchieved {
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            .frame(width: 180, height: 180)
                            .scaleEffect(todayRecord.isGoalAchieved ? 1.1 : 1.0)
                            .opacity(todayRecord.isGoalAchieved ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: todayRecord.isGoalAchieved)
                    }
                }
                .frame(height: 200)
                
                // 更新ボタン
                AsaButton(
                    title: stepCountService.isLoading ? "更新中..." : "歩数を更新",
                    action: {
                        Task {
                            await refreshData()
                        }
                    },
                    isEnabled: !stepCountService.isLoading && stepCountService.isAuthorized
                )
            }
        }
    }
    
    // MARK: - 統計とナビゲーション
    private var statisticsAndNavigationSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AsaCard {
                    VStack {
                        Text("\(todayRecord.achievementPercentage)%")
                            .font(.title.weight(.bold))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        Text("目標達成率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                AsaCard {
                    VStack {
                        Text(todayRecord.isGoalAchieved ? "達成!" : "未達成")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(todayRecord.isGoalAchieved ? .green : Color("AsaMutedSage"))
                        Text("今日の目標")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            AsaButton(
                title: "履歴を見る",
                action: {
                    showingHistory = true
                },
                color: Color("AsaMutedSage")
            )
        }
    }
    
    // MARK: - データ更新
    private func refreshData() async {
        await stepCountService.refreshData()
        
        // SwiftDataに歩数を保存
        todayRecord.updateStepCount(stepCountService.todayStepCount)
        
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: StepRecord.self, inMemory: true)
        .environment(StepCountService())
}
