import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct ProjectionView: View {
    @State var viewModel: ProjectionViewModel
    @State private var showAddScenarioSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    growthChartSection
                    scenarioComparisonSection
                    scenarioListSection
                }
                .padding()
            }
            .navigationTitle("成長予測")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddScenarioSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showAddScenarioSheet) {
                AddScenarioSheet(viewModel: viewModel)
            }
            .onAppear { viewModel.loadProjection() }
            .refreshable { viewModel.loadProjection() }
        }
    }

    private var growthChartSection: some View {
        GrowthProjectionChart(points: viewModel.projectionPoints)
            .padding(16)
            .background(AsaColors.softCream.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scenarioComparisonSection: some View {
        Group {
            if !viewModel.comparisonData.isEmpty {
                ScenarioLineChart(scenarios: viewModel.comparisonData)
                    .padding(16)
                    .background(AsaColors.softCream.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var scenarioListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("シナリオ")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if viewModel.scenarios.isEmpty {
                Text("シナリオを追加して比較してみましょう")
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.scenarios, id: \.id) { scenario in
                    scenarioRow(scenario)
                }
            }
        }
    }

    private func scenarioRow(_ scenario: Scenario) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(scenario.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AsaColors.darkSlate)

                    if scenario.isDefault {
                        Text("デフォルト")
                            .font(.caption2)
                            .foregroundStyle(AsaColors.coffeeBrown)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AsaColors.coffeeBrown.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Label(
                        formatPercent(scenario.annualReturnRate),
                        systemImage: "chart.line.uptrend.xyaxis"
                    )
                    Label(
                        formatPercent(scenario.inflationRate),
                        systemImage: "arrow.up.right.circle"
                    )
                    Label(
                        "\(scenario.projectionYears)年",
                        systemImage: "calendar"
                    )
                }
                .font(.caption)
                .foregroundStyle(AsaColors.mutedSage)
            }

            Spacer()

            Button {
                viewModel.selectScenario(scenario)
            } label: {
                Image(systemName: viewModel.selectedScenario?.id == scenario.id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(AsaColors.coffeeBrown)
            }
        }
        .padding(12)
        .background(
            viewModel.selectedScenario?.id == scenario.id
                ? AsaColors.coffeeBrown.opacity(0.08)
                : AsaColors.softCream.opacity(0.15)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteScenario(scenario)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private func formatPercent(_ value: Decimal) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue * 100
        return String(format: "%.1f%%", doubleValue)
    }
}

// MARK: - Add Scenario Sheet

private struct AddScenarioSheet: View {
    @State var viewModel: ProjectionViewModel
    @State private var name = ""
    @State private var returnRate: Double = 0.05
    @State private var inflationRate: Double = 0.02
    @State private var years: Int = 30
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("シナリオ名", text: $name)

                PercentageSlider(
                    title: "年間リターン率",
                    value: $returnRate,
                    range: -0.05...0.30,
                    step: 0.005
                )

                PercentageSlider(
                    title: "インフレ率",
                    value: $inflationRate,
                    range: 0.0...0.10,
                    step: 0.005
                )

                Stepper("予測年数: \(years)年", value: $years, in: 1...50)
            }
            .navigationTitle("シナリオを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        viewModel.addScenario(
                            name: name,
                            returnRate: Decimal(returnRate),
                            inflationRate: Decimal(inflationRate),
                            years: years
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
