import SwiftUI

struct StudyProgressView: View {
    @Environment(\.dismiss) private var dismiss
    
    let session: StudySession
    let currentIndex: Int
    let totalCount: Int
    let onSkip: () -> Void
    
    private var remainingCount: Int {
        max(0, totalCount - currentIndex)
    }
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 進捗サークル
                    ProgressCircleView(progress: progress, currentIndex: currentIndex, totalCount: totalCount)
                    
                    // 学習統計
                    StudyStatsGridView(session: session, remainingCount: remainingCount)
                    
                    // 時間情報
                    TimeStatsView(session: session, remainingCount: remainingCount)
                    
                    // アクションボタン
                    VStack(spacing: 12) {
                        if remainingCount > 0 {
                            Button(action: {
                                onSkip()
                                dismiss()
                            }) {
                                Text("学習を終了する")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("AsaMocha"))
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("続ける")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(Color("AsaCoffeeBrown"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AsaCoffeeBrown").opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("学習進捗")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
            }
        }
    }
}

struct ProgressCircleView: View {
    let progress: Double
    let currentIndex: Int
    let totalCount: Int
    
    var body: some View {
        ZStack {
            // 背景サークル
            Circle()
                .stroke(Color("AsaSoftCream").opacity(0.3), lineWidth: 12)
                .frame(width: 150, height: 150)
            
            // 進捗サークル
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color("AsaCoffeeBrown"),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // 中央のテキスト
            VStack(spacing: 4) {
                Text("\(currentIndex)")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("/ \(totalCount)")
                    .font(.title3)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                
                Text("完了")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    .textCase(.uppercase)
            }
        }
    }
}

struct StudyStatsGridView: View {
    let session: StudySession
    let remainingCount: Int
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StudyStatCard(
                title: "正解数",
                value: "\(session.correctAnswers)",
                subtitle: "問",
                icon: "checkmark.circle.fill",
                color: "AsaMutedSage"
            )
            
            StudyStatCard(
                title: "不正解数",
                value: "\(session.totalAnswers - session.correctAnswers)",
                subtitle: "問",
                icon: "xmark.circle.fill",
                color: "AsaMocha"
            )
            
            StudyStatCard(
                title: "正解率",
                value: "\(Int(session.correctRate * 100))",
                subtitle: "%",
                icon: "percent",
                color: "AsaCoffeeBrown"
            )
            
            StudyStatCard(
                title: "残り",
                value: "\(remainingCount)",
                subtitle: "枚",
                icon: "doc.text.fill",
                color: "AsaDarkSlate"
            )
        }
    }
}

struct StudyStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(color))
            
            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title.weight(.bold))
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct TimeStatsView: View {
    let session: StudySession
    let remainingCount: Int
    
    private var elapsedMinutes: Int {
        Int(session.duration / 60)
    }
    
    private var elapsedSeconds: Int {
        Int(session.duration) % 60
    }
    
    private var averageTimePerCard: Double {
        guard session.totalAnswers > 0 else { return 0 }
        return session.duration / Double(session.totalAnswers)
    }
    
    private var estimatedRemainingTime: Int {
        guard averageTimePerCard > 0 else { return 0 }
        return Int(Double(remainingCount) * averageTimePerCard / 60)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("時間統計")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                TimeInfoView(
                    title: "経過時間",
                    value: String(format: "%02d:%02d", elapsedMinutes, elapsedSeconds),
                    icon: "clock.fill",
                    color: "AsaCoffeeBrown"
                )
                
                Spacer()
                
                if remainingCount > 0 && averageTimePerCard > 0 {
                    TimeInfoView(
                        title: "推定残り時間",
                        value: "約\(estimatedRemainingTime)分",
                        icon: "hourglass",
                        color: "AsaMocha"
                    )
                }
            }
            
            if session.totalAnswers > 0 {
                HStack {
                    Text("1枚あたりの平均時間:")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    
                    Spacer()
                    
                    Text(String(format: "%.1f秒", averageTimePerCard))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color("AsaDarkSlate"))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("AsaSoftCream").opacity(0.2))
        )
    }
}

struct TimeInfoView: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(color))
            
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let session = StudySession()
    session.correctAnswers = 7
    session.totalAnswers = 10
    session.startTime = Date().addingTimeInterval(-300) // 5分前
    
    return StudyProgressView(
        session: session,
        currentIndex: 10,
        totalCount: 20,
        onSkip: {}
    )
}
