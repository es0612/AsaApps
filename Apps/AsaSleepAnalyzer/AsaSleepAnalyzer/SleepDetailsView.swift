//
//  SleepDetailsView.swift
//  AsaSleepAnalyzer
//
//  Created on 2025/08/05
//

import SwiftUI

struct SleepDetailsView: View {
    let sleepData: SleepData
    @State var viewModel: SleepAnalyzerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingNotesEditor = false
    @State private var editedNotes = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 日付とメイン情報
                    dateAndMainInfo
                    
                    // 睡眠時間詳細
                    sleepDurationDetails
                    
                    // 睡眠品質
                    sleepQualitySection
                    
                    // 睡眠効率
                    sleepEfficiencySection
                    
                    // 睡眠時間のビジュアル表示
                    sleepTimelineVisualization
                    
                    // メモ
                    notesSection
                    
                    // 改善提案
                    improvementSuggestions
                    
                }
                .padding()
            }
            .navigationTitle("睡眠詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
        .sheet(isPresented: $showingNotesEditor) {
            notesEditorSheet
        }
        .accentColor(Color("AsaCoffeeBrown"))
    }
    
    // MARK: - 日付とメイン情報
    
    private var dateAndMainInfo: some View {
        AsaCard {
            VStack(spacing: 16) {
                // 日付
                Text(formatDate(sleepData.date))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                // メイン睡眠情報
                HStack(spacing: 30) {
                    VStack {
                        Image(systemName: "moon.stars.fill")
                            .font(.title)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text(sleepData.formattedTotalSleepDuration)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("総睡眠時間")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Image(systemName: sleepData.qualityLevel.systemImageName)
                            .font(.title)
                            .foregroundColor(Color(sleepData.qualityLevel.color))
                        
                        Text(sleepData.formattedQualityScore)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("品質スコア")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Image(systemName: "gauge.medium")
                            .font(.title)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text(sleepData.formattedSleepEfficiency)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("睡眠効率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - 睡眠時間詳細
    
    private var sleepDurationDetails: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("睡眠時間詳細")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                VStack(spacing: 12) {
                    DetailRow(
                        icon: "bed.double.fill",
                        title: "就寝時刻",
                        value: sleepData.formattedBedtime,
                        color: Color("AsaMocha")
                    )
                    
                    DetailRow(
                        icon: "sunrise.fill",
                        title: "起床時刻",
                        value: sleepData.formattedWakeTime,
                        color: Color("AsaCoffeeBrown")
                    )
                    
                    DetailRow(
                        icon: "clock.fill",
                        title: "ベッドにいた時間",
                        value: formatDuration(calculateTimeInBed()),
                        color: Color("AsaMutedSage")
                    )
                    
                    DetailRow(
                        icon: "moon.fill",
                        title: "実際の睡眠時間",
                        value: sleepData.formattedTotalSleepDuration,
                        color: Color("AsaDarkSlate")
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - 睡眠品質セクション
    
    private var sleepQualitySection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("睡眠品質")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                HStack {
                    // 品質レベル表示
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: sleepData.qualityLevel.systemImageName)
                                .foregroundColor(Color(sleepData.qualityLevel.color))
                                .font(.title3)
                            
                            Text(sleepData.qualityLevel.rawValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(sleepData.qualityLevel.color))
                        }
                        
                        Text("スコア: \(sleepData.formattedQualityScore)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 品質スコアの円形プログレス
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .opacity(0.2)
                            .foregroundColor(Color("AsaMocha"))
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(sleepData.qualityScore / 10.0))
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .foregroundColor(Color(sleepData.qualityLevel.color))
                            .rotationEffect(Angle(degrees: 270.0))
                        
                        Text("\(Int(sleepData.qualityScore * 10))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                    .frame(width: 60, height: 60)
                }
                
                // 品質要因
                qualityFactorsView
            }
            .padding()
        }
    }
    
    // MARK: - 睡眠効率セクション
    
    private var sleepEfficiencySection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("睡眠効率")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sleepData.formattedSleepEfficiency)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text(efficiencyDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 効率プログレスバー
                    VStack {
                        ProgressView(value: sleepData.sleepEfficiency)
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(x: 1, y: 3, anchor: .center)
                            .tint(efficiencyColor)
                        
                        Text("理想: 85%以上")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 120)
                }
            }
            .padding()
        }
    }
    
    // MARK: - 睡眠タイムライン可視化
    
    private var sleepTimelineVisualization: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("睡眠タイムライン")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                if let bedtime = sleepData.bedtime, let wakeTime = sleepData.wakeTime {
                    SleepTimelineView(
                        bedtime: bedtime,
                        wakeTime: wakeTime,
                        sleepDuration: sleepData.totalSleepDuration
                    )
                } else {
                    Text("タイムラインデータが不十分です")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
    }
    
    // MARK: - メモセクション
    
    private var notesSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("メモ")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Button("編集") {
                        editedNotes = sleepData.notes
                        showingNotesEditor = true
                    }
                    .font(.caption)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                if sleepData.notes.isEmpty {
                    Text("メモを追加して睡眠パターンを記録しましょう")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                } else {
                    Text(sleepData.notes)
                        .font(.body)
                        .foregroundColor(Color("AsaDarkSlate"))
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
        }
    }
    
    // MARK: - 改善提案
    
    private var improvementSuggestions: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("改善提案")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(generateSuggestions(), id: \.self) { suggestion in
                        SuggestionRow(text: suggestion)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - 品質要因表示
    
    private var qualityFactorsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("品質要因")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaDarkSlate"))
            
            HStack(spacing: 16) {
                QualityFactorIndicator(
                    title: "睡眠時間",
                    isGood: sleepData.totalSleepDuration >= 7 * 3600,
                    icon: "clock.fill"
                )
                
                QualityFactorIndicator(
                    title: "睡眠効率",
                    isGood: sleepData.sleepEfficiency >= 0.85,
                    icon: "gauge.medium"
                )
                
                QualityFactorIndicator(
                    title: "規則性",
                    isGood: isRegularSleepTime(),
                    icon: "repeat"
                )
            }
        }
    }
    
    // MARK: - メモ編集シート
    
    private var notesEditorSheet: some View {
        NavigationView {
            VStack {
                TextEditor(text: $editedNotes)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("メモを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        showingNotesEditor = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        sleepData.notes = editedNotes
                        // ここでSwiftDataの保存処理を追加
                        showingNotesEditor = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%d時間%d分", hours, minutes)
    }
    
    private func calculateTimeInBed() -> TimeInterval {
        guard let bedtime = sleepData.bedtime, let wakeTime = sleepData.wakeTime else {
            return 0
        }
        return wakeTime.timeIntervalSince(bedtime)
    }
    
    private var efficiencyDescription: String {
        switch sleepData.sleepEfficiency {
        case 0.9...:
            return "優秀"
        case 0.85..<0.9:
            return "良好"
        case 0.8..<0.85:
            return "普通"
        case 0.7..<0.8:
            return "改善の余地あり"
        default:
            return "改善が必要"
        }
    }
    
    private var efficiencyColor: Color {
        switch sleepData.sleepEfficiency {
        case 0.85...:
            return .green
        case 0.7..<0.85:
            return Color("AsaMutedSage")
        default:
            return .orange
        }
    }
    
    private func isRegularSleepTime() -> Bool {
        // 簡単な実装：理想的な就寝時間（22:00-24:00）かどうかチェック
        guard let bedtime = sleepData.bedtime else { return false }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: bedtime)
        return hour >= 22 || hour <= 1
    }
    
    private func generateSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if sleepData.totalSleepDuration < 7 * 3600 {
            suggestions.append("7-9時間の睡眠を目指しましょう")
        }
        
        if sleepData.sleepEfficiency < 0.85 {
            suggestions.append("就寝前のリラックス時間を設けましょう")
        }
        
        if let bedtime = sleepData.bedtime {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: bedtime)
            if hour < 22 || hour > 1 {
                suggestions.append("22:00-24:00の間に就寝することをお勧めします")
            }
        }
        
        if sleepData.qualityScore < 6.0 {
            suggestions.append("寝室環境（温度、照明、騒音）を見直してみましょう")
        }
        
        if suggestions.isEmpty {
            suggestions.append("素晴らしい睡眠です！この調子で続けましょう")
        }
        
        return suggestions
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaDarkSlate"))
        }
    }
}

struct QualityFactorIndicator: View {
    let title: String
    let isGood: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(isGood ? .green : .orange)
                .font(.caption)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isGood ? .green : .orange)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SuggestionRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(Color("AsaMocha"))
                .font(.caption)
                .padding(.top, 2)
            
            Text(text)
                .font(.body)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Spacer()
        }
    }
}

struct SleepTimelineView: View {
    let bedtime: Date
    let wakeTime: Date
    let sleepDuration: TimeInterval
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("就寝")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(bedtime))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AsaMocha"))
                }
                
                Spacer()
                
                VStack {
                    Text("睡眠時間")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(sleepDuration))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("起床")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(wakeTime))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
            
            // タイムライン表示
            HStack(spacing: 0) {
                Circle()
                    .fill(Color("AsaMocha"))
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color("AsaCoffeeBrown"))
                    .frame(height: 4)
                
                Circle()
                    .fill(Color("AsaCoffeeBrown"))
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return String(format: "%d時間%d分", hours, minutes)
    }
}

#Preview {
    let sampleSleepData = SleepData(
        date: Date(),
        totalSleepDuration: 8 * 3600,
        sleepEfficiency: 0.92,
        qualityScore: 8.5
    )
    
    SleepDetailsView(
        sleepData: sampleSleepData,
        viewModel: SleepAnalyzerViewModel()
    )
}
