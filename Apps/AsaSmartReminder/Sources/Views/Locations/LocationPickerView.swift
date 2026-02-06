import AsaSmartReminderKit
import AsaUIKit
import MapKit
import SwiftUI

// MARK: - 場所選択ビュー

struct LocationPickerView: View {
    let dataService: ReminderDataService
    let onSelect: (ReminderLocation) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var pickerVM = LocationPickerViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var name = ""
    @State private var selectedCategory: LocationCategory = .custom

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 検索バー
                LocationSearchBarView(viewModel: pickerVM)

                // 地図
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    if let coord = pickerVM.selectedCoordinate {
                        // 選択されたピン
                        Annotation("", coordinate: coord) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundStyle(AsaColors.coffeeBrown)
                        }

                        // 半径プレビュー
                        MapCircle(center: coord, radius: pickerVM.selectedRadius)
                            .foregroundStyle(AsaColors.coffeeBrown.opacity(0.15))
                            .stroke(AsaColors.coffeeBrown, lineWidth: 2)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                }
                .frame(maxHeight: .infinity)

                // 設定パネル
                if pickerVM.selectedCoordinate != nil {
                    settingsPanel
                }
            }
            .navigationTitle("場所を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveLocation()
                    }
                    .disabled(!isValid)
                    .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - 設定パネル

    private var settingsPanel: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("場所名", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            // カテゴリ選択
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LocationCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            pickerVM.applyDefaultRadius(for: category)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: category.systemImageName)
                                    .font(.title3)
                                Text(category.displayName)
                                    .font(.caption2)
                            }
                            .frame(width: 56, height: 56)
                            .background(selectedCategory == category ? AsaColors.coffeeBrown : AsaColors.softCream)
                            .foregroundStyle(selectedCategory == category ? .white : AsaColors.darkSlate)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // 半径スライダー
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("ジオフェンス半径")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(pickerVM.selectedRadius))m")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AsaColors.coffeeBrown)
                }
                Slider(value: $pickerVM.selectedRadius, in: 10 ... 1000, step: 10)
                    .tint(AsaColors.coffeeBrown)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - バリデーション

    private var isValid: Bool {
        pickerVM.selectedCoordinate != nil && !effectiveName.isEmpty
    }

    private var effectiveName: String {
        name.isEmpty ? pickerVM.selectedName : name
    }

    // MARK: - 保存

    private func saveLocation() {
        guard let coordinate = pickerVM.selectedCoordinate else { return }
        let location = ReminderLocation(
            name: effectiveName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radius: pickerVM.selectedRadius,
            address: pickerVM.selectedAddress,
            category: selectedCategory
        )
        do {
            try dataService.saveLocation(location)
            onSelect(location)
        } catch {
            // エラーハンドリング
        }
    }
}
