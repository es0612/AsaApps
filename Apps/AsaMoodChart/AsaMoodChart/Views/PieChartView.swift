// AsaApps/Apps/AsaMoodChart/Views/PieChartView.swift
import SwiftUI
import Charts
import AsaUIKit

/// 気分分布を表示する円グラフ
struct PieChartView: View {
    let moodEntries: [MoodEntry]
    @State private var selectedMood: String?
    @State private var hoveredAngle: Angle?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // グラフタイトル
            Text("気分の分布")
                .font(.headline)
                .foregroundColor(AsaColors.coffeeBrown)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                // 円グラフ
                pieChart
                
                // 凡例
                legendView
            }
            .padding(.horizontal)
            
            // 選択された気分の詳細
            if let selectedMood = selectedMood {
                selectedMoodDetail(for: selectedMood)
            }
            
            // 統計情報
            statisticsView
        }
        .asaCardStyle()
        .onAppear {
            // 最初に最多気分を選択
            selectedMood = mostFrequentMood
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var pieChart: some View {
        Chart(moodDistribution, id: \.mood) { data in
            SectorMark(
                angle: .value("件数", data.count),
                innerRadius: .ratio(0.4),
                angularInset: 2
            )
            .foregroundStyle(colorForMood(data.mood))
            .cornerRadius(4)
            .opacity(selectedMood == nil || selectedMood == data.mood ? 1.0 : 0.6)
        }
        .frame(width: 180, height: 180)
        .chartBackground { proxy in
            // 中央の統計表示
            VStack(spacing: 4) {
                Text("\(moodEntries.count)")
                    .font(.title.bold())
                    .foregroundColor(AsaColors.coffeeBrown)
                
                Text("記録")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .onTapGesture { location in
            selectedMood = findNearestMoodInPie(to: location)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedMood)
    }
    
    @ViewBuilder
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(moodDistribution, id: \.mood) { data in
                legendItem(for: data)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMood = selectedMood == data.mood ? nil : data.mood
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private func legendItem(for data: (mood: String, count: Int, percentage: Double)) -> some View {
        HStack(spacing: 8) {
            // カラーインジケーター
            RoundedRectangle(cornerRadius: 3)
                .fill(colorForMood(data.mood))
                .frame(width: 12, height: 12)
                .scaleEffect(selectedMood == data.mood ? 1.2 : 1.0)
            
            // 気分emoji
            Text(emojiForMoodName(data.mood))
                .font(.caption)
            
            // 気分名と統計
            VStack(alignment: .leading, spacing: 2) {
                Text(data.mood)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                Text("\(data.count)回 (\(String(format: "%.1f", data.percentage))%)")
                    .font(.caption2)
                    .foregroundColor(AsaColors.mutedSage)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
        .background(
            selectedMood == data.mood ? 
            AsaColors.softCream.opacity(0.3) : Color.clear
        )
        .cornerRadius(6)
        .animation(.easeInOut(duration: 0.2), value: selectedMood)
    }
    
    @ViewBuilder
    private func selectedMoodDetail(for moodName: String) -> some View {
        let data = moodDistribution.first { $0.mood == moodName }
        
        if let moodData = data {
            HStack(spacing: 16) {
                // 大きな気分emoji
                Text(emojiForMoodName(moodName))
                    .font(.largeTitle)
                    .scaleEffect(1.2)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(moodName)
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("記録回数")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Text("\(moodData.count)回")
                                .font(.title3.bold())
                                .foregroundColor(AsaColors.darkSlate)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("全体に占める割合")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Text("\(String(format: "%.1f", moodData.percentage))%")
                                .font(.title3.bold())
                                .foregroundColor(colorForMood(moodName))
                        }
                    }
                }
                
                Spacer()
                
                // プログレスリング
                ZStack {
                    Circle()
                        .stroke(AsaColors.softCream, lineWidth: 6)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: moodData.percentage / 100)
                        .stroke(
                            colorForMood(moodName),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding()
            .background(AsaColors.softCream.opacity(0.3))
            .cornerRadius(16)
            .padding(.horizontal)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private var statisticsView: some View {
        HStack(spacing: 20) {
            statisticsItem(
                title: "最多気分",
                value: mostFrequentMood,
                subtitle: "\(moodCounts[mostFrequentMood] ?? 0)回"
            )
            
            statisticsItem(
                title: "気分タイプ",
                value: "\(moodCounts.count)",
                subtitle: "種類"
            )
            
            statisticsItem(
                title: "多様性",
                value: diversityScore,
                subtitle: "バランス"
            )
        }
        .padding(.horizontal)
    }
    
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
    
    // MARK: - Computed Properties
    
    private var moodCounts: [String: Int] {
        moodEntries.moodCounts
    }
    
    private var moodDistribution: [(mood: String, count: Int, percentage: Double)] {
        let total = Double(moodEntries.count)
        return moodCounts.map { (mood: $0.key, count: $0.value, percentage: Double($0.value) / total * 100) }
            .sorted { $0.count > $1.count }
    }
    
    private var mostFrequentMood: String {
        moodDistribution.first?.mood ?? "😊"
    }
    
    private var diversityScore: String {
        let uniqueCount = moodCounts.count
        switch uniqueCount {
        case 1: return "低"
        case 2...3: return "中"
        case 4...5: return "高"
        default: return "最高"
        }
    }
    
    // MARK: - Helper Methods
    
    private func emojiForMoodName(_ moodName: String) -> String {
        switch moodName {
        case "悲しい": return "😢"
        case "イライラ": return "😤"
        case "疲れ": return "😴"
        case "良い": return "😊"
        case "最高": return "😍"
        default: return "😊"
        }
    }
    
    private func colorForMood(_ moodName: String) -> Color {
        switch moodName {
        case "悲しい": return AsaColors.mutedSage.opacity(0.8)
        case "イライラ": return .red.opacity(0.7)
        case "疲れ": return AsaColors.darkSlate.opacity(0.6)
        case "良い": return .green.opacity(0.7)
        case "最高": return AsaColors.coffeeBrown
        default: return AsaColors.mocha
        }
    }
    
    private func findNearestMoodInPie(to location: CGPoint) -> String? {
        // 簡易実装：ランダムな気分を返す
        // 実際の実装では、タップ位置の角度を計算して対応する気分を特定する
        return moodDistribution.randomElement()?.mood
    }
}

// MARK: - Preview

#Preview {
    let sampleEntries = [
        MoodEntry(date: Date(), emoji: "😊"),
        MoodEntry(date: Date(), emoji: "😊"),
        MoodEntry(date: Date(), emoji: "😊"),
        MoodEntry(date: Date(), emoji: "😢"),
        MoodEntry(date: Date(), emoji: "😍"),
        MoodEntry(date: Date(), emoji: "😍"),
        MoodEntry(date: Date(), emoji: "😤"),
        MoodEntry(date: Date(), emoji: "😴")
    ]
    
    return PieChartView(moodEntries: sampleEntries)
        .padding()
        .background(AsaColors.softCream.opacity(0.1))
}