import SwiftUI
import Charts
import AsaEduGameKit
import AsaUIKit

// MARK: - 正答率推移チャート

/// 最近10セッションの正答率推移を折れ線グラフで表示
struct AccuracyChartView: View {

    // MARK: - Properties

    let sessions: [GameSession]

    // MARK: - Computed

    /// グラフ用のデータ（最新10件、古い順にソート）
    private var chartData: [(index: Int, accuracy: Double, mode: GameMode)] {
        let recent = sessions
            .sorted { $0.startedAt < $1.startedAt }
            .suffix(10)

        return recent.enumerated().map { index, session in
            (index: index + 1, accuracy: session.accuracy * 100, mode: session.gameMode)
        }
    }

    // MARK: - Body

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("せいとうりつのすいい")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)

                if chartData.isEmpty {
                    Text("データがありません")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                } else {
                    Chart {
                        ForEach(chartData, id: \.index) { data in
                            LineMark(
                                x: .value("セッション", data.index),
                                y: .value("せいとうりつ", data.accuracy)
                            )
                            .foregroundStyle(AsaColors.coffeeBrown)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("セッション", data.index),
                                y: .value("せいとうりつ", data.accuracy)
                            )
                            .foregroundStyle(Color(data.mode.themeColorName))
                            .symbolSize(40)
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)%")
                                    .font(.system(size: 10, design: .rounded))
                            }
                            AxisGridLine()
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)")
                                    .font(.system(size: 10, design: .rounded))
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }
}

// MARK: - モード別獲得星数チャート

/// モード別の合計獲得星数を棒グラフで表示
struct StarsChartView: View {

    // MARK: - Properties

    let modeStats: [GameMode: ProgressViewModel.ModeStatistics]

    // MARK: - Computed

    /// グラフ用のデータ
    private var chartData: [(mode: String, stars: Int, color: Color)] {
        GameMode.allCases.map { mode in
            let sessions = modeStats[mode]
            let stars = sessions?.totalCorrect ?? 0
            return (mode: mode.displayName, stars: stars, color: Color(mode.themeColorName))
        }
    }

    // MARK: - Body

    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("モードべつせいかいすう")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)

                let hasData = chartData.contains { $0.stars > 0 }

                if !hasData {
                    Text("データがありません")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                } else {
                    Chart {
                        ForEach(chartData, id: \.mode) { data in
                            BarMark(
                                x: .value("モード", data.mode),
                                y: .value("せいかい", data.stars)
                            )
                            .foregroundStyle(data.color)
                            .cornerRadius(6)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                Text("\(value.as(Int.self) ?? 0)")
                                    .font(.system(size: 10, design: .rounded))
                            }
                            AxisGridLine()
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                Text(value.as(String.self) ?? "")
                                    .font(.system(size: 11, design: .rounded))
                            }
                        }
                    }
                    .frame(height: 180)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            AccuracyChartView(sessions: [])
            StarsChartView(modeStats: [:])
        }
        .padding()
    }
}
