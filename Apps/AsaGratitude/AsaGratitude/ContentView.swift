//
//  ContentView.swift
//  AsaGratitude
//  
//  Created on 2025/07/02
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GratitudeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日の感謝エントリー数と励ましの言葉
                    TodaysSummaryView(viewModel: viewModel)
                    
                    // 感謝の名言
                    QuoteCardView(viewModel: viewModel)
                    
                    // クイックアクション
                    QuickActionsView(viewModel: viewModel)
                    
                    // 最近の感謝エントリー
                    RecentGratitudeView(viewModel: viewModel)
                }
                .padding()
            }
            .navigationTitle("感謝日記")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.isShowingAddEntry) {
                AddGratitudeView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.refreshQuote()
            }
        }
    }
}

struct TodaysSummaryView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaSoftCream").opacity(0.3)) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title2)
                    Text("今日の感謝")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日記録した感謝")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.todayEntries.count)件")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("連続記録")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.stats.currentStreak)日")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
                
                if viewModel.todayEntries.isEmpty {
                    Text("今日もたくさんの小さな幸せを見つけてみましょう 🌸")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                } else {
                    Text("素晴らしい！今日も感謝の気持ちを記録できました ✨")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
        }
    }
}

struct QuoteCardView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        AsaCard(backgroundColor: Color("AsaMocha").opacity(0.1)) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "quote.bubble")
                        .foregroundColor(Color("AsaMocha"))
                        .font(.title3)
                    Text("今日の言葉")
                        .font(.headline)
                        .foregroundColor(Color("AsaMocha"))
                    Spacer()
                    Button(action: {
                        viewModel.refreshQuote()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color("AsaMocha"))
                            .font(.subheadline)
                    }
                }
                
                Text("「\(viewModel.currentQuote.text)」")
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                if let author = viewModel.currentQuote.author {
                    Text("— \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
}

struct QuickActionsView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            AsaButton(title: "今日の感謝を記録", action: {
                viewModel.showAddEntry()
            })
            
            HStack(spacing: 12) {
                NavigationLink(destination: GratitudeHistoryView(viewModel: viewModel)) {
                    AsaCard(backgroundColor: Color("AsaMutedSage").opacity(0.2)) {
                        VStack {
                            Image(systemName: "book")
                                .font(.title2)
                                .foregroundColor(Color("AsaMutedSage"))
                            Text("履歴")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: GratitudeStatsView(viewModel: viewModel)) {
                    AsaCard(backgroundColor: Color("AsaCoffeeBrown").opacity(0.2)) {
                        VStack {
                            Image(systemName: "chart.bar")
                                .font(.title2)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("統計")
                                .font(.caption)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: GratitudeCalendarView(viewModel: viewModel)) {
                    AsaCard(backgroundColor: Color("AsaMocha").opacity(0.2)) {
                        VStack {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(Color("AsaMocha"))
                            Text("カレンダー")
                                .font(.caption)
                                .foregroundColor(Color("AsaMocha"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct RecentGratitudeView: View {
    @ObservedObject var viewModel: GratitudeViewModel
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title3)
                    Text("最近の感謝")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Spacer()
                    if !viewModel.gratitudeEntries.isEmpty {
                        NavigationLink(destination: GratitudeHistoryView(viewModel: viewModel)) {
                            Text("すべて表示")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                }
                
                if viewModel.gratitudeEntries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.system(size: 40))
                            .foregroundColor(Color("AsaMutedSage").opacity(0.5))
                        Text("まだ感謝の記録がありません")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("最初の感謝を記録してみましょう！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.recentEntries)) { entry in
                            GratitudeRowView(entry: entry)
                        }
                    }
                }
            }
        }
    }
}

struct GratitudeRowView: View {
    let entry: GratitudeEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Text(entry.category.emoji)
                    .font(.title2)
                Text(entry.moodLevel.emoji)
                    .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.shortContent)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack {
                    Text(entry.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(entry.category.color).opacity(0.2))
                        .foregroundColor(Color(entry.category.color))
                        .cornerRadius(8)
                    
                    Text(entry.moodLevel.stars)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("\(entry.dateFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
