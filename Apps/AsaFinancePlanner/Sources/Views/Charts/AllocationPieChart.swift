import SwiftUI
import Charts
import AsaUIKit
import AsaFinancePlannerKit

struct AllocationPieChart: View {
    let allocations: [AssetAllocation]
    let title: String
    @State private var selectedClass: AssetClass?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if allocations.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
    }

    private var chartContent: some View {
        VStack(spacing: 16) {
            Chart(allocations) { allocation in
                let percentage = displayPercentage(for: allocation)
                SectorMark(
                    angle: .value("配分", percentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(Color(hex: allocation.assetClass.colorHex))
                .opacity(selectedClass == nil || selectedClass == allocation.assetClass ? 1.0 : 0.4)
                .annotation(position: .overlay) {
                    if percentage >= 0.08 {
                        Text(String(format: "%.0f%%", percentage * 100))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 200)
            .accessibilityLabel("資産配分チャート")

            legendView
        }
    }

    private var legendView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 8) {
            ForEach(sortedAllocations) { allocation in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: allocation.assetClass.colorHex))
                        .frame(width: 10, height: 10)

                    Text(allocation.assetClass.displayName)
                        .font(.caption)
                        .foregroundStyle(AsaColors.darkSlate)
                        .lineLimit(1)

                    Spacer()

                    Text(String(format: "%.1f%%", displayPercentage(for: allocation) * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AsaColors.mutedSage)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie")
                .font(.largeTitle)
                .foregroundStyle(AsaColors.mutedSage.opacity(0.5))
            Text("資産データがありません")
                .font(.caption)
                .foregroundStyle(AsaColors.mutedSage)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var sortedAllocations: [AssetAllocation] {
        allocations.sorted { displayPercentage(for: $0) > displayPercentage(for: $1) }
    }

    private func displayPercentage(for allocation: AssetAllocation) -> Double {
        allocation.currentPercentage > 0 ? allocation.currentPercentage : allocation.targetPercentage
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
