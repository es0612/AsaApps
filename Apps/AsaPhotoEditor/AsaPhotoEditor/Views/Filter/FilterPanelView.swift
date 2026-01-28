import SwiftUI

// MARK: - FilterPanelView
struct FilterPanelView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // フィルター選択
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterPreset.allCases) { preset in
                        FilterPresetButton(
                            preset: preset,
                            isSelected: viewModel.filterSettings.preset == preset,
                            previewImage: viewModel.originalImage
                        ) {
                            viewModel.recordHistory()
                            viewModel.filterSettings.preset = preset
                            viewModel.filterSettings.intensity = preset.defaultIntensity
                            viewModel.schedulePreviewUpdate()
                        }
                    }
                }
                .padding(.horizontal)
            }

            // 強度スライダー（対応フィルターのみ）
            if viewModel.filterSettings.preset.supportsIntensity {
                VStack(spacing: 8) {
                    HStack {
                        Text("強度")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.asaSoftCream)

                        Spacer()

                        Text(String(format: "%.1f", viewModel.filterSettings.intensity))
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(.asaSoftCream.opacity(0.7))
                    }

                    Slider(
                        value: $viewModel.filterSettings.intensity,
                        in: viewModel.filterSettings.preset.intensityRange
                    )
                    .tint(Color.asaCoffeeBrown)
                    .onChange(of: viewModel.filterSettings.intensity) { _, _ in
                        viewModel.schedulePreviewUpdate()
                    }
                }
                .padding(.horizontal)
            }

            // リセットボタン
            if viewModel.filterSettings.preset != .none {
                HStack {
                    Spacer()

                    Button {
                        viewModel.resetFilter()
                    } label: {
                        Text("フィルターを解除")
                            .font(.caption)
                            .foregroundColor(.asaSoftCream.opacity(0.7))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - FilterPresetButton
struct FilterPresetButton: View {
    let preset: FilterPreset
    let isSelected: Bool
    let previewImage: UIImage?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.asaMocha.opacity(0.5))
                        .frame(width: 60, height: 60)

                    // プレビューサムネイルがあれば表示（将来の拡張用）
                    Image(systemName: preset.iconName)
                        .font(.title2)
                        .foregroundColor(.white)

                    // 選択インジケーター
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.asaCoffeeBrown, lineWidth: 3)
                            .frame(width: 60, height: 60)
                    }
                }

                Text(preset.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .asaSoftCream.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
    }
}

// MARK: - Preview
#Preview {
    FilterPanelView(viewModel: PhotoEditorViewModel())
        .background(Color.asaDarkSlate)
}
