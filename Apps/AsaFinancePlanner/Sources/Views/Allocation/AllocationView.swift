import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct AllocationView: View {
    @State var viewModel: AllocationViewModel
    @State private var showRebalanceSheet = false
    @State private var showAddAssetSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    currentAllocationSection
                    targetAllocationSection
                    riskToleranceSection
                    assetListSection
                }
                .padding()
            }
            .navigationTitle("資産配分")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddAssetSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showRebalanceSheet) {
                RebalanceSheet(suggestions: viewModel.rebalanceSuggestions)
            }
            .sheet(isPresented: $showAddAssetSheet) {
                AddAssetSheet(viewModel: viewModel)
            }
            .onAppear { viewModel.loadAllocation() }
            .refreshable { viewModel.loadAllocation() }
        }
    }

    private var currentAllocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AllocationPieChart(
                allocations: viewModel.currentAllocations,
                title: "現在の資産配分"
            )
        }
        .padding(16)
        .background(AsaColors.softCream.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var targetAllocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AllocationPieChart(
                allocations: viewModel.targetAllocations,
                title: "推奨配分"
            )

            if !viewModel.rebalanceSuggestions.isEmpty {
                AsaButton(title: "リバランス提案を確認") {
                    showRebalanceSheet = true
                }
            }
        }
        .padding(16)
        .background(AsaColors.softCream.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var riskToleranceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("リスク許容度")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            Picker("リスク許容度", selection: Binding(
                get: { viewModel.riskTolerance },
                set: { viewModel.updateRiskTolerance($0) }
            )) {
                ForEach(RiskTolerance.allCases, id: \.self) { tolerance in
                    Text(tolerance.displayName).tag(tolerance)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(AsaColors.softCream.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var assetListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("保有資産")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if let plan = viewModel.plan, !plan.assets.isEmpty {
                ForEach(plan.assets, id: \.id) { asset in
                    assetRow(asset)
                }
            } else {
                Text("資産を追加してください")
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
    }

    private func assetRow(_ asset: Asset) -> some View {
        HStack {
            Image(systemName: asset.assetClass.iconName)
                .foregroundStyle(Color(hex: asset.assetClass.colorHex))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.subheadline)
                    .foregroundStyle(AsaColors.darkSlate)
                Text(asset.assetClass.displayName)
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(asset.currentValue))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(String(format: "%+.1f%%", asset.gainPercentage * 100))
                    .font(.caption)
                    .foregroundStyle(asset.gainPercentage >= 0 ? .green : .red)
            }
        }
        .padding(12)
        .background(AsaColors.softCream.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteAsset(asset)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let intValue = NSDecimalNumber(decimal: amount).intValue
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return (formatter.string(from: NSNumber(value: intValue)) ?? "\(intValue)") + "円"
    }
}

// MARK: - Add Asset Sheet

private struct AddAssetSheet: View {
    @State var viewModel: AllocationViewModel
    @State private var name = ""
    @State private var assetClass: AssetClass = .domesticStock
    @State private var currentValue: Decimal = .zero
    @State private var acquisitionCost: Decimal = .zero
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("資産名", text: $name)

                Picker("資産クラス", selection: $assetClass) {
                    ForEach(AssetClass.allCases, id: \.self) { cls in
                        Label(cls.displayName, systemImage: cls.iconName)
                            .tag(cls)
                    }
                }

                CurrencyTextField(title: "現在の評価額", value: $currentValue)
                CurrencyTextField(title: "取得コスト", value: $acquisitionCost)
            }
            .navigationTitle("資産を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        viewModel.addAsset(
                            name: name,
                            assetClass: assetClass,
                            currentValue: currentValue,
                            acquisitionCost: acquisitionCost
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .disabled(name.isEmpty || currentValue <= .zero)
                }
            }
        }
    }
}
