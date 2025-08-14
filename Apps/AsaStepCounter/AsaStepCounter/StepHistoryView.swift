//
//  StepHistoryView.swift
//  AsaStepCounter
//
//  Created on 2025/08/15
//

import SwiftUI
import SwiftData

struct StepHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StepCountService.self) private var stepCountService
    @Query(sort: \StepRecord.date, order: .reverse) private var stepRecords: [StepRecord]
    
    @State private var selectedPeriod: HistoryPeriod = .week
    
    enum HistoryPeriod: String, CaseIterable {
        case week = "7日間"
        case month = "30日間"
        case all = "全期間"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return Int.max
            }
        }
    }
    
    // 選択された期間のデータをフィルタ
    private var filteredRecords: [StepRecord] {
        if selectedPeriod == .all {
            return Array(stepRecords.prefix(100)) // 最大100件
        } else {
            return Array(stepRecords.prefix(selectedPeriod.days))
        }
    }
    
    // 統計計算
    private var statistics: (totalSteps: Int, avgSteps: Int, achievedDays: Int, totalDays: Int) {
        let records = filteredRecords
        let totalSteps = records.reduce(0) { $0 + $1.stepCount }
        let avgSteps = records.isEmpty ? 0 : totalSteps / records.count
        let achievedDays = records.filter { $0.isGoalAchieved }.count
        let totalDays = records.count
        return (totalSteps, avgSteps, achievedDays, totalDays)
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
                        // 期間選択
                        periodSelectionCard
                        
                        // 統計サマリー
                        statisticsCard
                        
                        // 歩数履歴リスト
                        historyListSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("歩数履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 期間選択カード
    private var periodSelectionCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("表示期間")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                HStack(spacing: 8) {
                    ForEach(HistoryPeriod.allCases, id: \.self) { period in
                        Button(period.rawValue) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPeriod = period
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color("AsaCoffeeBrown") : Color("AsaSoftCream"))
                        .foregroundColor(selectedPeriod == period ? .white : Color("AsaCoffeeBrown"))
                        .cornerRadius(8)
                        .font(.caption.weight(.medium))
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 統計カード
    private var statisticsCard: some View {
        AsaCard {
            VStack(spacing: 20) {
                Text("統計情報")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatisticItem(
                        title: "総歩数",
                        value: statistics.totalSteps.formatted(.number),
                        unit: "歩",
                        color: Color("AsaCoffeeBrown")
                    )
                    
                    StatisticItem(
                        title: "平均歩数",
                        value: statistics.avgSteps.formatted(.number),
                        unit: "歩/日",
                        color: Color("AsaMutedSage")
                    )
                    
                    StatisticItem(
                        title: "達成率",
                        value: statistics.totalDays > 0 ? "\(Int(Double(statistics.achievedDays) / Double(statistics.totalDays) * 100))" : "0",
                        unit: "%",
                        color: statistics.achievedDays > statistics.totalDays / 2 ? .green : .orange
                    )
                    
                    StatisticItem(
                        title: "達成日数",
                        value: "\(statistics.achievedDays)",
                        unit: "/\(statistics.totalDays)日",
                        color: Color("AsaCoffeeBrown")
                    )
                }
            }
        }
    }
    
    // MARK: - 履歴リストセクション
    private var historyListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("歩数記録")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .padding(.leading, 4)
            
            if filteredRecords.isEmpty {
                AsaCard {
                    VStack(spacing: 16) {
                        Image(systemName: "footprints")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("まだ歩数記録がありません")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("アプリを使い始めると、ここに歩数履歴が表示されます。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredRecords) { record in
                        HistoryRowView(record: record)
                    }
                }
            }
        }
    }
}

// MARK: - 統計アイテムビュー
struct StatisticItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color("AsaSoftCream").opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - 履歴行ビュー
struct HistoryRowView: View {
    let record: StepRecord
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(record.date)
    }
    
    private var progressBarWidth: CGFloat {
        let maxWidth: CGFloat = 100
        let progress = min(record.achievementRate, 1.0)
        return maxWidth * progress
    }
    
    var body: some View {
        AsaCard {
            HStack(spacing: 16) {
                // 日付
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateFormatter.string(from: record.date))
                        .font(.caption.weight(.medium))
                        .foregroundColor(isToday ? Color("AsaCoffeeBrown") : .secondary)
                    
                    if isToday {
                        Text("今日")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color("AsaCoffeeBrown"))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                .frame(width: 60, alignment: .leading)
                
                // 歩数と進捗
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(record.stepCount) 歩")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Spacer()
                        
                        Text("目標: \(record.dailyGoal)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // プログレスバー
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("AsaSoftCream"))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(record.isGoalAchieved ? .green : Color("AsaCoffeeBrown"))
                            .frame(width: progressBarWidth, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: progressBarWidth)
                    }
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("\(record.achievementPercentage)%")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(record.isGoalAchieved ? .green : Color("AsaMutedSage"))
                        
                        Spacer()
                        
                        if record.isGoalAchieved {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("達成")
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StepRecord.self, configurations: config)
    
    StepHistoryView()
        .modelContainer(container)
        .environment(StepCountService())
}