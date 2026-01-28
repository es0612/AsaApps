import SwiftUI

// MARK: - CropPanelView
struct CropPanelView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 回転・反転ボタン
            HStack(spacing: 20) {
                CropActionButton(
                    icon: "rotate.left",
                    label: "左回転"
                ) {
                    viewModel.recordHistory()
                    viewModel.cropSettings.rotateCounterClockwise()
                    viewModel.schedulePreviewUpdate()
                }

                CropActionButton(
                    icon: "rotate.right",
                    label: "右回転"
                ) {
                    viewModel.recordHistory()
                    viewModel.cropSettings.rotateClockwise()
                    viewModel.schedulePreviewUpdate()
                }

                Divider()
                    .frame(height: 40)
                    .background(Color.asaSoftCream.opacity(0.3))

                CropActionButton(
                    icon: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                    label: "左右反転",
                    isActive: viewModel.cropSettings.isFlippedHorizontally
                ) {
                    viewModel.recordHistory()
                    viewModel.cropSettings.toggleHorizontalFlip()
                    viewModel.schedulePreviewUpdate()
                }

                CropActionButton(
                    icon: "arrow.up.and.down.righttriangle.up.righttriangle.down",
                    label: "上下反転",
                    isActive: viewModel.cropSettings.isFlippedVertically
                ) {
                    viewModel.recordHistory()
                    viewModel.cropSettings.toggleVerticalFlip()
                    viewModel.schedulePreviewUpdate()
                }
            }
            .padding(.horizontal)

            // アスペクト比選択
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AspectRatio.allCases) { ratio in
                        AspectRatioButton(
                            ratio: ratio,
                            isSelected: viewModel.cropSettings.aspectRatio == ratio
                        ) {
                            viewModel.recordHistory()
                            viewModel.cropSettings.aspectRatio = ratio
                            viewModel.schedulePreviewUpdate()
                        }
                    }
                }
                .padding(.horizontal)
            }

            // リセットボタン
            HStack {
                Spacer()

                Button {
                    viewModel.resetCrop()
                } label: {
                    Text("クロップをリセット")
                        .font(.caption)
                        .foregroundColor(.asaSoftCream.opacity(0.7))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - CropActionButton
struct CropActionButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .asaCoffeeBrown : .asaSoftCream)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.asaSoftCream.opacity(0.7))
            }
            .frame(width: 60)
        }
    }
}

// MARK: - AspectRatioButton
struct AspectRatioButton: View {
    let ratio: AspectRatio
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.asaCoffeeBrown : Color.asaSoftCream.opacity(0.5), lineWidth: 2)
                        .frame(width: ratioWidth, height: ratioHeight)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.asaCoffeeBrown.opacity(0.3))
                            .frame(width: ratioWidth, height: ratioHeight)
                    }
                }
                .frame(width: 40, height: 40)

                Text(ratio.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .asaSoftCream.opacity(0.7))
            }
            .frame(width: 50)
        }
    }

    private var ratioWidth: CGFloat {
        guard let r = ratio.ratio else { return 30 }
        return r > 1 ? 30 : 30 * r
    }

    private var ratioHeight: CGFloat {
        guard let r = ratio.ratio else { return 30 }
        return r > 1 ? 30 / r : 30
    }
}

// MARK: - Preview
#Preview {
    CropPanelView(viewModel: PhotoEditorViewModel())
        .background(Color.asaDarkSlate)
}
