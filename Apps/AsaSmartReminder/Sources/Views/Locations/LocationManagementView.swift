import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - 場所管理ビュー

struct LocationManagementView: View {
    @Bindable var viewModel: SmartReminderViewModel
    let dataService: ReminderDataService

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.locations.isEmpty {
                    EmptyStateView(
                        icon: "mappin.slash",
                        title: "場所が登録されていません",
                        description: "＋ボタンから新しい場所を追加しましょう"
                    )
                } else {
                    List {
                        // カテゴリ別にグループ化
                        ForEach(groupedLocations, id: \.category) { group in
                            Section(group.category.displayName) {
                                ForEach(group.locations) { location in
                                    LocationCardView(location: location)
                                }
                                .onDelete { offsets in
                                    for index in offsets {
                                        viewModel.deleteLocation(group.locations[index])
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("場所管理")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddLocation = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .tint(AsaColors.coffeeBrown)
                }
            }
            .sheet(isPresented: $viewModel.showingAddLocation) {
                LocationPickerView(
                    dataService: dataService,
                    onSelect: { location in
                        viewModel.showingAddLocation = false
                        viewModel.loadData()
                    }
                )
            }
        }
    }

    // MARK: - カテゴリ別グループ化

    private struct LocationGroup {
        let category: LocationCategory
        let locations: [ReminderLocation]
    }

    private var groupedLocations: [LocationGroup] {
        let grouped = Dictionary(grouping: viewModel.locations) { $0.category }
        return LocationCategory.allCases
            .compactMap { category in
                guard let locations = grouped[category], !locations.isEmpty else { return nil }
                return LocationGroup(category: category, locations: locations)
            }
    }
}

// MARK: - 場所カード

struct LocationCardView: View {
    let location: ReminderLocation

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AsaColors.softCream)
                    .frame(width: 44, height: 44)
                Image(systemName: location.category.systemImageName)
                    .font(.title3)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                if let address = location.address {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Label("\(Int(location.radius))m", systemImage: "circle.dashed")
                    Label("\(location.activeReminderCount)件", systemImage: "bell.fill")
                }
                .font(.caption2)
                .foregroundStyle(AsaColors.mutedSage)
            }

            Spacer()
        }
    }
}
