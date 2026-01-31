import SwiftUI
import Charts

/// 資産配分円グラフ
struct AllocationPieChart: View {
    let allocations: [AllocationData]
    let title: String

    @State private var selectedSlice: AllocationData?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            if allocations.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundStyle(Color("AsaMutedSage"))

            Text("データがありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var chartContent: some View {
        HStack(spacing: 20) {
            // 円グラフ
            Chart(allocations) { item in
                SectorMark(
                    angle: .value("Value", item.percentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(item.color)
                .opacity(selectedSlice == nil || selectedSlice?.id == item.id ? 1 : 0.5)
            }
            .frame(width: 150, height: 150)
            .chartBackground { chartProxy in
                if let selected = selectedSlice {
                    VStack(spacing: 2) {
                        Text(selected.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(String(format: "%.1f%%", selected.percentage))
                            .font(.headline.bold())
                            .foregroundStyle(Color("AsaCoffeeBrown"))
                    }
                } else {
                    VStack(spacing: 2) {
                        Text("合計")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(allocations.count)")
                            .font(.headline.bold())
                            .foregroundStyle(Color("AsaCoffeeBrown"))
                    }
                }
            }

            // 凡例
            VStack(alignment: .leading, spacing: 8) {
                ForEach(allocations.prefix(5)) { item in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedSlice?.id == item.id {
                                selectedSlice = nil
                            } else {
                                selectedSlice = item
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)

                            Text(item.name)
                                .font(.caption)
                                .foregroundStyle(Color("AsaDarkSlate"))
                                .lineLimit(1)

                            Spacer()

                            Text(String(format: "%.1f%%", item.percentage))
                                .font(.caption.bold())
                                .foregroundStyle(Color("AsaCoffeeBrown"))
                        }
                    }
                }

                if allocations.count > 5 {
                    Text("他 \(allocations.count - 5) 件")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Allocation Data

struct AllocationData: Identifiable, Equatable {
    let id: String
    let name: String
    let value: Decimal
    let percentage: Double
    let color: Color

    static func == (lhs: AllocationData, rhs: AllocationData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sector Allocation Chart

struct SectorAllocationChart: View {
    let sectorAllocations: [SectorAllocation]

    private var allocations: [AllocationData] {
        let colors: [Color] = [
            Color("AsaCoffeeBrown"),
            Color("AsaMocha"),
            Color("AsaMutedSage"),
            Color("AsaDarkSlate"),
            .blue,
            .green,
            .orange,
            .purple,
            .pink,
            .cyan
        ]

        return sectorAllocations.enumerated().map { index, sector in
            AllocationData(
                id: sector.sectorName,
                name: sector.sectorName,
                value: sector.value,
                percentage: sector.percentage,
                color: colors[index % colors.count]
            )
        }
    }

    var body: some View {
        AllocationPieChart(
            allocations: allocations,
            title: "セクター別配分"
        )
    }
}

// MARK: - Asset Type Allocation Chart

struct AssetTypeAllocationChart: View {
    let assetTypeAllocations: [AssetTypeAllocation]

    private var allocations: [AllocationData] {
        let colorMap: [AssetType: Color] = [
            .stock: Color("AsaCoffeeBrown"),
            .etf: Color("AsaMocha"),
            .mutualFund: .blue,
            .bond: .green,
            .crypto: .orange,
            .other: Color("AsaMutedSage")
        ]

        return assetTypeAllocations.map { allocation in
            AllocationData(
                id: allocation.assetType.rawValue,
                name: allocation.assetType.displayName,
                value: allocation.value,
                percentage: allocation.percentage,
                color: colorMap[allocation.assetType] ?? .gray
            )
        }
    }

    var body: some View {
        AllocationPieChart(
            allocations: allocations,
            title: "資産タイプ別配分"
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        AllocationPieChart(
            allocations: [
                AllocationData(id: "1", name: "Technology", value: 5000, percentage: 50, color: Color("AsaCoffeeBrown")),
                AllocationData(id: "2", name: "Healthcare", value: 2000, percentage: 20, color: Color("AsaMocha")),
                AllocationData(id: "3", name: "Finance", value: 1500, percentage: 15, color: .blue),
                AllocationData(id: "4", name: "Energy", value: 1000, percentage: 10, color: .green),
                AllocationData(id: "5", name: "Other", value: 500, percentage: 5, color: .gray)
            ],
            title: "セクター別配分"
        )

        AllocationPieChart(allocations: [], title: "空のチャート")
    }
    .padding()
    .background(Color("AsaDarkSlate").opacity(0.05))
}
