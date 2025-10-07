//
//  ActiveTimersView.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import SwiftUI

struct ActiveTimersView: View {
    @Bindable var viewModel: MultiTimerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingStopAllAlert = false
    
    // グリッドのレイアウト設定
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // ステータスヘッダー
                    statusHeaderView

                    // アクティブタイマーグリッド
                    if viewModel.activeTimers.isEmpty {
                        emptyActiveTimersView
                            .padding(.top, 40)
                    } else {
                        activeTimersGridView
                    }
                }
                .padding()
            }
            .navigationTitle("実行中タイマー")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if !viewModel.activeTimers.isEmpty {
                            showingStopAllAlert = true
                        }
                    }) {
                        Image(systemName: "stop.circle")
                            .foregroundColor(viewModel.activeTimers.isEmpty ? .gray : Color("AsaMutedSage"))
                    }
                    .disabled(viewModel.activeTimers.isEmpty)
                }
            }
            .alert("全タイマーを一時停止", isPresented: $showingStopAllAlert) {
                Button("一時停止", role: .destructive) {
                    viewModel.pauseAllTimers()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("実行中の全てのタイマーを一時停止しますか？")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var statusHeaderView: some View {
        VStack(spacing: 12) {
            // 実行中タイマー数と制限表示
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("実行中")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(viewModel.activeTimerCount)")
                        .font(.title.weight(.bold))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                Text("/ \(viewModel.maxConcurrentTimers)")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 新規タイマー開始可能状況
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.canStartNewTimer ? "開始可能" : "上限到達")
                        .font(.caption)
                        .foregroundColor(viewModel.canStartNewTimer ? .green : .orange)
                    
                    Circle()
                        .fill(viewModel.canStartNewTimer ? .green : .orange)
                        .frame(width: 12, height: 12)
                }
            }
            .padding()
            .background(Color("AsaSoftCream").opacity(0.2))
            .cornerRadius(12)
            
            // 一時停止中のタイマーがあれば表示
            if !viewModel.multiTimer.pausedTimers.isEmpty {
                HStack {
                    Image(systemName: "pause.circle")
                        .foregroundColor(.orange)
                    Text("\(viewModel.multiTimer.pausedTimers.count)個のタイマーが一時停止中")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button("全て再開") {
                        for timer in viewModel.multiTimer.pausedTimers {
                            viewModel.startTimer(with: timer.id)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var activeTimersGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.activeTimers) { session in
                    CompactTimerCardView(
                        session: session,
                        onPause: {
                            if session.state == .running {
                                viewModel.pauseTimer(with: session.id)
                            } else {
                                viewModel.startTimer(with: session.id)
                            }
                        },
                        onStop: {
                            viewModel.stopTimer(with: session.id)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.activeTimers.count)
    }
    
    private var emptyActiveTimersView: some View {
        VStack(spacing: 24) {
            // アニメーション付きアイコン
            ZStack {
                Circle()
                    .stroke(Color("AsaCoffeeBrown").opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "play.circle")
                    .font(.system(size: 50))
                    .foregroundColor(Color("AsaCoffeeBrown").opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("実行中のタイマーなし")
                    .font(.title2.weight(.medium))
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("タイマーを開始して、効率的に時間を管理しましょう")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // 待機中のタイマー情報
            if !viewModel.multiTimer.pendingTimers.isEmpty {
                VStack(spacing: 8) {
                    Text("待機中のタイマー: \(viewModel.multiTimer.pendingTimers.count)個")
                        .font(.caption)
                        .foregroundColor(Color("AsaMocha"))
                    
                    Button("最初のタイマーを開始") {
                        if let firstPendingTimer = viewModel.multiTimer.pendingTimers.first {
                            viewModel.startTimer(with: firstPendingTimer.id)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("AsaCoffeeBrown").opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top)
            }
            
            // 一時停止中のタイマー情報
            if !viewModel.multiTimer.pausedTimers.isEmpty {
                VStack(spacing: 8) {
                    Text("一時停止中: \(viewModel.multiTimer.pausedTimers.count)個")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.multiTimer.pausedTimers.prefix(3)) { timer in
                                Button(action: {
                                    viewModel.startTimer(with: timer.id)
                                }) {
                                    VStack {
                                        Text(timer.name)
                                            .font(.caption2)
                                            .lineLimit(1)
                                        Text(timer.formattedRemainingTime)
                                            .font(.caption2.weight(.medium))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundColor(.orange)
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ActiveTimersView(viewModel: MultiTimerViewModel())
}