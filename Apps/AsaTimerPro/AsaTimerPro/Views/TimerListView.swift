//
//  TimerListView.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import SwiftUI

struct TimerListView: View {
    @Bindable var viewModel: MultiTimerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingDeleteAlert = false
    @State private var timerToDelete: UUID?
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // フィルター・ソートセクション
                    filterAndSortSection
                    
                    // タイマーリスト
                    if viewModel.filteredTimers.isEmpty {
                        emptyStateView
                            .padding(.top, 40)
                    } else {
                        timerListContent
                    }
                }
                .padding()
            }
            .navigationTitle("タイマー一覧")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilterSheet = true }) {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterSheetContent
            }
            .alert("タイマーを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    if let id = timerToDelete {
                        viewModel.deleteTimer(with: id)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このタイマーを完全に削除しますか？この操作は取り消せません。")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var filterAndSortSection: some View {
        HStack {
            // カテゴリフィルター
            Menu {
                Button("全て") {
                    viewModel.selectedCategory = nil
                }
                
                ForEach(TimerCategory.allCases) { category in
                    Button(action: {
                        viewModel.selectedCategory = category
                    }) {
                        Label(category.displayName, systemImage: category.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text(viewModel.selectedCategory?.displayName ?? "全カテゴリ")
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("AsaCoffeeBrown").opacity(0.1))
                .foregroundColor(Color("AsaCoffeeBrown"))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // ソートメニュー
            Menu {
                ForEach(MultiTimerViewModel.SortOption.allCases) { option in
                    Button(action: {
                        viewModel.sortOption = option
                    }) {
                        HStack {
                            Text(option.displayName)
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(viewModel.sortOption.displayName)
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("AsaMocha").opacity(0.1))
                .foregroundColor(Color("AsaMocha"))
                .cornerRadius(8)
            }
        }
    }
    
    private var timerListContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredTimers) { session in
                    TimerCardView(
                        session: session,
                        onStart: {
                            viewModel.startTimer(with: session.id)
                        },
                        onPause: {
                            viewModel.pauseTimer(with: session.id)
                        },
                        onStop: {
                            viewModel.stopTimer(with: session.id)
                        },
                        onDelete: {
                            timerToDelete = session.id
                            showingDeleteAlert = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.filteredTimers.count)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(Color("AsaCoffeeBrown").opacity(0.5))
            
            Text("タイマーがありません")
                .font(.title2.weight(.medium))
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("新しいタイマーを作成して、時間管理を始めましょう！")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            AsaButton(
                title: "タイマーを作成",
                action: {
                    // タブを「新規作成」に切り替える処理
                    // 注意: この機能を完全に実装するにはTabViewのselectionバインディングが必要
                    print("新規タイマー作成タブに移動")
                },
                color: Color("AsaCoffeeBrown")
            )
            .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var filterSheetContent: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                // 完了済みタイマーの表示設定
                VStack(alignment: .leading, spacing: 12) {
                    Text("表示設定")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Toggle(isOn: $viewModel.showCompletedTimers) {
                        Text("完了済みタイマーを表示")
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                    .tint(Color("AsaCoffeeBrown"))
                }
                
                // 統計情報
                VStack(alignment: .leading, spacing: 12) {
                    Text("今日の統計")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("総タイマー数")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(viewModel.todayStats.totalTimers)")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("完了率")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(viewModel.todayStats.completionPercentage)%")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                    .padding()
                    .background(Color("AsaSoftCream").opacity(0.2))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("フィルター・設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        showingFilterSheet = false
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    TimerListView(viewModel: MultiTimerViewModel())
}