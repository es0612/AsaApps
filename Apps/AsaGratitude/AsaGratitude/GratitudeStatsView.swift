//
//  GratitudeStatsView.swift
//  AsaGratitude
//  
//  Created on 2025/07/02
//

import SwiftUI

struct GratitudeStatsView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 全体統計カード
                OverallGratitudeStatsView(viewModel: viewModel)
                
                // 期間別統計
                PeriodStatsView(viewModel: viewModel)
                
                // カテゴリー別統計
                CategoryStatsView(viewModel: viewModel)
                
                // 気持ち別統計
                MoodStatsView(viewModel: viewModel)
                
                // ランダム感謝エントリー
                RandomGratitudeView(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("感謝の統計")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OverallGratitudeStatsView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaCoffeeBrown").opacity(0.1)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("全体統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCardView(
                        title: "総感謝エントリー",
                        value: "\(viewModel.stats.totalEntries)",
                        unit: "件",
                        color: Color("AsaCoffeeBrown")
                    )
                    
                    StatCardView(
                        title: "現在の連続記録",
                        value: "\(viewModel.stats.currentStreak)",
                        unit: "日",
                        color: Color("AsaMutedSage")
                    )
                    
                    StatCardView(
                        title: "最長連続記録",
                        value: "\(viewModel.stats.longestStreak)",
                        unit: "日",
                        color: Color("AsaMocha")
                    )
                    
                    StatCardView(
                        title: "1日平均",
                        value: String(format: "%.1f", viewModel.stats.averageEntriesPerDay),
                        unit: "件",
                        color: Color("AsaDarkSlate")
                    )
                }
            }
        }
    }
}

struct PeriodStatsView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaMutedSage").opacity(0.1)) {
            VStack(alignment: .leading, spacing: 16) {
                Text("期間別統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaMutedSage"))
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCardView(
                        title: "今週の感謝",
                        value: "\(viewModel.stats.thisWeekEntries)",
                        unit: "件",
                        color: Color("AsaMutedSage")
                    )
                    
                    StatCardView(
                        title: "今月の感謝",
                        value: "\(viewModel.stats.thisMonthEntries)",
                        unit: "件",
                        color: Color("AsaCoffeeBrown")
                    )
                }
            }
        }
    }
}

struct CategoryStatsView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("カテゴリー別統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                if viewModel.categoryStats.isEmpty {
                    Text("まだ感謝の記録がありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                } else {
                    ForEach(viewModel.categoryStats.prefix(5), id: \.0) { category, count in
                        HStack {
                            HStack(spacing: 8) {
                                Text(category.emoji)
                                    .font(.title3)
                                Text(category.displayName)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Text("\(count)件")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(category.color))
                        }
                        .padding(.vertical, 4)
                        
                        if category != viewModel.categoryStats.prefix(5).last?.0 {
                            Divider()
                        }
                    }
                    
                    if let mostCommon = viewModel.stats.mostCommonCategory {
                        HStack {
                            Text("最も多いカテゴリー:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(mostCommon.emoji) \(mostCommon.displayName)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(mostCommon.color))
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
}

struct MoodStatsView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("気持ち別統計")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                if viewModel.moodStats.isEmpty {
                    Text("まだ感謝の記録がありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                } else {
                    ForEach(viewModel.moodStats, id: \.0) { mood, count in
                        HStack {
                            HStack(spacing: 8) {
                                Text(mood.emoji)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mood.displayName)
                                        .font(.subheadline)
                                    Text(mood.stars)
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(count)件")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(mood.color))
                        }
                        .padding(.vertical, 4)
                        
                        if mood != viewModel.moodStats.last?.0 {
                            Divider()
                        }
                    }
                    
                    if let mostCommon = viewModel.stats.mostCommonMood {
                        HStack {
                            Text("最も多い気持ち:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(mostCommon.emoji) \(mostCommon.displayName)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(mostCommon.color))
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }
}

struct RandomGratitudeView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    @State private var currentRandomEntry: GratitudeEntry?
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaSoftCream").opacity(0.3)) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "shuffle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title3)
                    Text("過去の感謝を振り返る")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                    Button(action: {
                        currentRandomEntry = viewModel.randomEntry
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .font(.subheadline)
                    }
                }
                
                if let randomEntry = currentRandomEntry ?? viewModel.randomEntry {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack {
                                Text(randomEntry.category.emoji)
                                    .font(.title2)
                                Text(randomEntry.moodLevel.emoji)
                                    .font(.caption)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(randomEntry.content)
                                    .font(.body)
                                    .lineLimit(nil)
                                
                                HStack {
                                    Text(randomEntry.category.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color(randomEntry.category.color).opacity(0.2))
                                        .foregroundColor(Color(randomEntry.category.color))
                                        .cornerRadius(8)
                                    
                                    Text(randomEntry.moodLevel.stars)
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text(randomEntry.dateFormatted)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                } else {
                    Text("まだ感謝の記録がありません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                }
            }
        }
        .onAppear {
            currentRandomEntry = viewModel.randomEntry
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        GratitudeStatsView(viewModel: GratitudeViewModel())
    }
}