// AsaApps/Apps/AsaMoodChart/Views/LineChartView.swift
import SwiftUI
import Charts
import AsaUIKit

/// 気分の時系列変化を表示する線グラフ
struct LineChartView: View {
    let moodEntries: [MoodEntry]
    @State private var selectedEntry: MoodEntry?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // グラフタイトル
            Text("気分の変化")
                .font(.headline)
                .foregroundColor(AsaColors.coffeeBrown)
                .padding(.horizontal)
            
            // 選択された気分の詳細表示
            if let selectedEntry = selectedEntry {
                selectedMoodDetail(for: selectedEntry)
            }
            
            // 線グラフ
            Chart(moodEntries.sortedByDate) { entry in
                // 線グラフ
                LineMark(
                    x: .value("日付", entry.date),
                    y: .value("気分", entry.moodValue)
                )
                .foregroundStyle(AsaColors.coffeeBrown.gradient)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                
                // ポイントマーカー
                PointMark(
                    x: .value("日付", entry.date),
                    y: .value("気分", entry.moodValue)
                )
                .foregroundStyle(AsaColors.coffeeBrown)
                .symbolSize(selectedEntry?.id == entry.id ? 120 : 60)
                
                // 選択されたポイントの垂直線
                if let selectedEntry = selectedEntry,
                   selectedEntry.id == entry.id {
                    RuleMark(x: .value("日付", selectedEntry.date))
                        .foregroundStyle(AsaColors.mutedSage.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5]))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, moodEntries.count / 7))) { value in
                    AxisGridLine()
                        .foregroundStyle(AsaColors.mutedSage.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(AsaColors.mutedSage)
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                    AxisGridLine()
                        .foregroundStyle(AsaColors.softCream.opacity(0.8))
                    AxisTick()
                        .foregroundStyle(AsaColors.mutedSage)
                    AxisValueLabel {
                        if let moodValue = value.as(Double.self) {
                            Text(moodEmoji(for: moodValue))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYScale(domain: 0.5...5.5)
            .chartBackground { proxy in
                // グラデーション背景
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AsaColors.softCream.opacity(0.1),
                                AsaColors.softCream.opacity(0.3)
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(12)
            }
            .chartScrollableAxes(.horizontal)
            .onTapGesture { location in
                // タップ位置に最も近いエントリを選択
                selectedEntry = findNearestEntry(to: location)
            }
            .padding(.horizontal)
            
            // 統計情報
            statisticsView
        }
        .asaCardStyle()
        .onAppear {
            // アニメーション付きで最初のデータポイントを選択
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedEntry = moodEntries.sortedByDate.first
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// 選択された気分の詳細表示
    @ViewBuilder
    private func selectedMoodDetail(for entry: MoodEntry) -> some View {
        HStack(spacing: 12) {
            // 気分emoji
            Text(entry.emoji)
                .font(.title2)
                .scaleEffect(1.2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.moodName)
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                
                Text(entry.formattedDate + " (\(entry.weekdayString))")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
            
            Spacer()
            
            // 気分値
            VStack {
                Text(String(format: "%.1f", entry.moodValue))
                    .font(.title2.bold())
                    .foregroundColor(AsaColors.darkSlate)
                Text("/ 5.0")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .padding()
        .background(AsaColors.softCream.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
        .transition(.scale.combined(with: .opacity))
    }
    
    /// 統計情報表示
    @ViewBuilder
    private var statisticsView: some View {
        HStack(spacing: 20) {
            statisticsItem(
                title: "平均",
                value: String(format: "%.1f", moodEntries.averageMoodValue),
                subtitle: "/ 5.0"
            )
            
            statisticsItem(
                title: "記録日数",
                value: "\(moodEntries.count)",
                subtitle: "日間"
            )
            
            statisticsItem(
                title: "最頻気分",
                value: moodEntries.mostFrequentMood,
                subtitle: moodName(for: moodEntries.mostFrequentMood)
            )
        }
        .padding(.horizontal)
    }
    
    /// 統計項目
    @ViewBuilder
    private func statisticsItem(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(AsaColors.coffeeBrown)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(AsaColors.darkSlate.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    /// 気分値に対応するemojiを返す
    private func moodEmoji(for value: Double) -> String {
        switch value {
        case 1.0: return "😢"
        case 2.0: return "😤" 
        case 3.0: return "😴"
        case 4.0: return "😊"
        case 5.0: return "😍"
        default: return "😊"
        }
    }
    
    /// emojiに対応する気分名を返す
    private func moodName(for emoji: String) -> String {
        switch emoji {
        case "😢": return "悲しい"
        case "😤": return "イライラ"
        case "😴": return "疲れ"
        case "😊": return "良い"
        case "😍": return "最高"
        default: return "普通"
        }
    }
    
    /// タップ位置に最も近いエントリを見つける
    private func findNearestEntry(to location: CGPoint) -> MoodEntry? {
        // 簡易実装：最初のエントリを返す
        // 実際の実装では、タップ位置を基に最近接エントリを計算する
        return moodEntries.sortedByDate.randomElement()
    }
}

// MARK: - Preview

#Preview {
    let sampleEntries = [
        MoodEntry(date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(), emoji: "😊"),
        MoodEntry(date: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date(), emoji: "😢"),
        MoodEntry(date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(), emoji: "😍"),
        MoodEntry(date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(), emoji: "😤"),
        MoodEntry(date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), emoji: "😴"),
        MoodEntry(date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(), emoji: "😊"),
        MoodEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), emoji: "😍")
    ]
    
    return LineChartView(moodEntries: sampleEntries)
        .padding()
        .background(AsaColors.softCream.opacity(0.1))
}