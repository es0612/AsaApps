//
//  TimerCardView.swift
//  AsaTimerPro
//
//  Created on 2025/09/05
//

import SwiftUI

struct TimerCardView: View {
    let session: TimerSession
    let onStart: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch session.state {
        case .running:
            return Color("AsaCoffeeBrown").opacity(0.1)
        case .paused:
            return Color("AsaMocha").opacity(0.1)
        case .completed:
            return Color("AsaMutedSage").opacity(0.1)
        case .cancelled:
            return Color.gray.opacity(0.1)
        default:
            return Color("AsaSoftCream").opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        session.category.color
    }
    
    private var statusText: String {
        switch session.state {
        case .created:
            return "待機中"
        case .running:
            return "実行中"
        case .paused:
            return "一時停止"
        case .completed:
            return "完了"
        case .cancelled:
            return "キャンセル済み"
        }
    }
    
    private var statusColor: Color {
        switch session.state {
        case .created:
            return Color("AsaCoffeeBrown")
        case .running:
            return .green
        case .paused:
            return .orange
        case .completed:
            return Color("AsaMutedSage")
        case .cancelled:
            return .gray
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー部分
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // カテゴリとステータス
                    HStack(spacing: 8) {
                        Label(session.category.displayName, systemImage: session.category.icon)
                            .font(.caption)
                            .foregroundColor(session.category.color)
                        
                        Spacer()
                        
                        Text(statusText)
                            .font(.caption.weight(.medium))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // タイマー名
                    Text(session.name)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaDarkSlate"))
                        .lineLimit(2)
                }
                
                // 削除ボタン
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // プログレス表示
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(session.formattedCurrentTime)
                        .font(.system(.title2, design: .monospaced).weight(.bold))
                        .foregroundColor(session.isActive ? Color("AsaCoffeeBrown") : Color("AsaDarkSlate"))
                    
                    Spacer()
                    
                    Text("/ \(session.formattedDuration)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                // プログレスバー
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 6)
                            .opacity(0.3)
                            .foregroundColor(Color("AsaSoftCream"))
                        
                        Rectangle()
                            .frame(width: min(CGFloat(session.progress) * geometry.size.width, geometry.size.width), height: 6)
                            .foregroundColor(session.category.color)
                            .animation(.linear(duration: 0.5), value: session.progress)
                    }
                    .cornerRadius(3)
                }
                .frame(height: 6)
            }
            
            // メモ（あれば表示）
            if let memo = session.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // 繰り返し情報
            if session.isRepeating {
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundColor(Color("AsaMocha"))
                    Text("繰り返し: \(session.repeatCount)回目")
                        .font(.caption)
                        .foregroundColor(Color("AsaMocha"))
                }
            }
            
            // アクションボタン
            HStack(spacing: 12) {
                if session.state == .created || session.state == .paused {
                    AsaButton(
                        title: session.state == .paused ? "再開" : "開始",
                        action: onStart,
                        color: Color("AsaCoffeeBrown"),
                        isEnabled: true
                    )
                    .frame(maxWidth: .infinity)
                }
                
                if session.state == .running {
                    AsaButton(
                        title: "一時停止",
                        action: onPause,
                        color: Color("AsaMocha"),
                        isEnabled: true
                    )
                    .frame(maxWidth: .infinity)
                }
                
                if session.state == .running || session.state == .paused {
                    AsaButton(
                        title: "停止",
                        action: onStop,
                        color: Color("AsaMutedSage"),
                        isEnabled: true
                    )
                    .frame(maxWidth: .infinity)
                }
                
                // 完了済みの場合は統計情報を表示
                if session.state == .completed {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("完了時刻")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let endTime = session.endTime {
                            Text(endTime, style: .time)
                                .font(.caption.weight(.medium))
                                .foregroundColor(Color("AsaDarkSlate"))
                        }
                    }
                    
                    Spacer()
                    
                    if session.isRepeating {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("総実行回数")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(session.repeatCount)回")
                                .font(.caption.weight(.medium))
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .scaleEffect(session.isActive ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: session.isActive)
    }
}

// MARK: - Compact Timer Card (for Active Timers View)

struct CompactTimerCardView: View {
    let session: TimerSession
    let onPause: () -> Void
    let onStop: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // ヘッダー
            HStack {
                Label(session.category.displayName, systemImage: session.category.icon)
                    .font(.caption)
                    .foregroundColor(session.category.color)
                
                Spacer()
                
                Text(session.state == .running ? "実行中" : "一時停止")
                    .font(.caption.weight(.medium))
                    .foregroundColor(session.state == .running ? .green : .orange)
            }
            
            // タイマー名
            Text(session.name)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaDarkSlate"))
                .lineLimit(1)
            
            // 時間表示
            Text(session.formattedRemainingTime)
                .font(.system(.title, design: .monospaced).weight(.bold))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            // プログレスリング（簡易版）
            ZStack {
                Circle()
                    .stroke(Color("AsaSoftCream").opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(session.progress))
                    .stroke(session.category.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: session.progress)
            }
            
            // コントロールボタン
            HStack(spacing: 8) {
                Button(action: onPause) {
                    Image(systemName: session.state == .running ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderedProminent)
                .tint(session.state == .running ? Color("AsaMocha") : Color("AsaCoffeeBrown"))
                .controlSize(.small)
                
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AsaMutedSage"))
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color("AsaSoftCream").opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(session.category.color, lineWidth: 1.5)
        )
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        TimerCardView(
            session: TimerSession(
                name: "朝の読書タイム",
                category: .study,
                duration: 1800,
                currentTime: 600,
                state: .running,
                memo: "今日は技術書を読む予定"
            ),
            onStart: {},
            onPause: {},
            onStop: {},
            onDelete: {}
        )
        
        CompactTimerCardView(
            session: TimerSession(
                name: "作業集中時間",
                category: .work,
                duration: 3600,
                currentTime: 1200,
                state: .running
            ),
            onPause: {},
            onStop: {}
        )
    }
    .padding()
}