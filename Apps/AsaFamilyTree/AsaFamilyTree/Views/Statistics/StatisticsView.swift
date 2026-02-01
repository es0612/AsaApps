import SwiftUI
import Charts
import AsaFamilyTreeKit
import AsaUIKit

struct StatisticsView: View {
    // MARK: - Environment

    @Environment(FamilyTreeViewModel.self) private var viewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.appState == .loading {
                    ProgressView("読み込み中...")
                } else if let stats = viewModel.statistics {
                    statisticsContent(stats: stats)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("統計")
        }
    }

    // MARK: - Statistics Content

    private func statisticsContent(stats: TreeStatistics) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // 概要カード
                summaryCards(stats: stats)

                // 年齢分布チャート
                if !stats.ageDistribution.isEmpty {
                    ageDistributionChart(stats: stats)
                }

                // 世代別人数チャート
                if !stats.generationDistribution.isEmpty {
                    generationChart(stats: stats)
                }

                // 性別分布
                genderDistributionChart(stats: stats)
            }
            .padding()
        }
    }

    // MARK: - Summary Cards

    private func summaryCards(stats: TreeStatistics) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "総メンバー数",
                value: "\(stats.totalMembers)",
                systemImage: "person.3.fill",
                color: AsaColors.coffeeBrown
            )

            StatCard(
                title: "存命",
                value: "\(stats.aliveMembers)",
                systemImage: "heart.fill",
                color: .green
            )

            StatCard(
                title: "故人",
                value: "\(stats.deceasedMembers)",
                systemImage: "leaf.fill",
                color: .gray
            )

            StatCard(
                title: "世代数",
                value: "\(stats.generationCount)",
                systemImage: "arrow.down.to.line",
                color: AsaColors.mocha
            )

            StatCard(
                title: "婚姻数",
                value: "\(stats.marriageCount)",
                systemImage: "heart.circle.fill",
                color: .pink
            )

            if let avgAge = stats.averageAgeOfLiving {
                StatCard(
                    title: "平均年齢",
                    value: String(format: "%.1f歳", avgAge),
                    systemImage: "calendar",
                    color: AsaColors.mutedSage
                )
            }
        }
    }

    // MARK: - Age Distribution Chart

    private func ageDistributionChart(stats: TreeStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("年齢分布")
                .font(.headline)

            Chart {
                ForEach(AgeRange.allCases.sorted(), id: \.self) { range in
                    let count = stats.ageDistribution[range] ?? 0
                    BarMark(
                        x: .value("年齢層", range.displayName),
                        y: .value("人数", count)
                    )
                    .foregroundStyle(AsaColors.coffeeBrown.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption2)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Generation Chart

    private func generationChart(stats: TreeStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("世代別人数")
                .font(.headline)

            Chart {
                ForEach(stats.generationDistribution.keys.sorted(), id: \.self) { generation in
                    let count = stats.generationDistribution[generation] ?? 0
                    BarMark(
                        x: .value("世代", "第\(generation + 1)世代"),
                        y: .value("人数", count)
                    )
                    .foregroundStyle(AsaColors.mocha.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Gender Distribution Chart

    private func genderDistributionChart(stats: TreeStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("性別分布")
                .font(.headline)

            HStack(spacing: 20) {
                Chart {
                    SectorMark(
                        angle: .value("人数", stats.maleCount),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(Gender.male.color)

                    SectorMark(
                        angle: .value("人数", stats.femaleCount),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(Gender.female.color)

                    if stats.otherGenderCount > 0 {
                        SectorMark(
                            angle: .value("人数", stats.otherGenderCount),
                            innerRadius: .ratio(0.5)
                        )
                        .foregroundStyle(Gender.other.color)
                    }
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 8) {
                    GenderLegendItem(gender: .male, count: stats.maleCount)
                    GenderLegendItem(gender: .female, count: stats.femaleCount)
                    if stats.otherGenderCount > 0 {
                        GenderLegendItem(gender: .other, count: stats.otherGenderCount)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(AsaColors.mutedSage)

            Text("統計データがありません")
                .font(.title3)
                .fontWeight(.medium)

            Text("家族メンバーを追加すると\n統計が表示されます")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Gender Legend Item

struct GenderLegendItem: View {
    let gender: Gender
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(gender.color)
                .frame(width: 12, height: 12)

            Text(gender.displayName)
                .font(.caption)

            Text("\(count)人")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .environment(FamilyTreeViewModel())
}
