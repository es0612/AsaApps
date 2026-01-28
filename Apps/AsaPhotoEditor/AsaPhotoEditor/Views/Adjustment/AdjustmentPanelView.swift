import SwiftUI

// MARK: - AdjustmentPanelView
struct AdjustmentPanelView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel
    @State private var selectedType: AdjustmentType = .brightness

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // 調整タイプ選択
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AdjustmentType.allCases) { type in
                        AdjustmentTypeButton(
                            type: type,
                            isSelected: selectedType == type,
                            value: type.getValue(from: viewModel.adjustment),
                            action: {
                                selectedType = type
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // スライダー
            VStack(spacing: 8) {
                HStack {
                    Text(selectedType.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.asaSoftCream)

                    Spacer()

                    Text(formatValue(selectedType.getValue(from: viewModel.adjustment), for: selectedType))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.asaSoftCream.opacity(0.7))

                    Button {
                        resetValue(for: selectedType)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                            .foregroundColor(.asaSoftCream.opacity(0.7))
                    }
                }

                Slider(
                    value: bindingForType(selectedType),
                    in: selectedType.range
                )
                .tint(Color.asaCoffeeBrown)
                .onChange(of: viewModel.adjustment) { _, _ in
                    viewModel.recordHistory()
                    viewModel.schedulePreviewUpdate()
                }
            }
            .padding(.horizontal)

            // リセットボタン
            HStack {
                Spacer()

                Button {
                    viewModel.resetAdjustment()
                } label: {
                    Text("すべてリセット")
                        .font(.caption)
                        .foregroundColor(.asaSoftCream.opacity(0.7))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Private Methods

    private func bindingForType(_ type: AdjustmentType) -> Binding<Double> {
        Binding(
            get: { type.getValue(from: viewModel.adjustment) },
            set: { newValue in
                type.setValue(newValue, to: &viewModel.adjustment)
            }
        )
    }

    private func formatValue(_ value: Double, for type: AdjustmentType) -> String {
        switch type {
        case .contrast, .saturation:
            return String(format: "%.2f", value)
        default:
            return String(format: "%+.2f", value)
        }
    }

    private func resetValue(for type: AdjustmentType) {
        viewModel.recordHistory()
        type.setValue(type.defaultValue, to: &viewModel.adjustment)
        viewModel.schedulePreviewUpdate()
    }
}

// MARK: - AdjustmentTypeButton
struct AdjustmentTypeButton: View {
    let type: AdjustmentType
    let isSelected: Bool
    let value: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.asaCoffeeBrown : Color.asaMocha.opacity(0.5))
                        .frame(width: 44, height: 44)

                    Image(systemName: type.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.white)

                    // 変更インジケーター
                    if value != type.defaultValue {
                        Circle()
                            .fill(Color.asaCoffeeBrown)
                            .frame(width: 8, height: 8)
                            .offset(x: 16, y: -16)
                    }
                }

                Text(type.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .asaSoftCream.opacity(0.7))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AdjustmentPanelView(viewModel: PhotoEditorViewModel())
        .background(Color.asaDarkSlate)
}
