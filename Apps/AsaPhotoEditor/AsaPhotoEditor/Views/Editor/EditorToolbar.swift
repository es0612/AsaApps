import SwiftUI
import PhotosUI

// MARK: - EditorToolbar
struct EditorToolbar: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.asaMocha)

            HStack(spacing: 0) {
                ForEach(EditorMode.allCases) { mode in
                    ToolbarButton(
                        mode: mode,
                        isSelected: viewModel.currentMode == mode
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.currentMode = mode
                        }
                    }
                }

                Spacer()

                // 写真選択ボタン
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images
                ) {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                        Text("新規")
                            .font(.caption2)
                    }
                    .foregroundColor(.asaSoftCream)
                    .frame(width: 60, height: 50)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.asaMocha)
        }
    }
}

// MARK: - ToolbarButton
struct ToolbarButton: View {
    let mode: EditorMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: mode.iconName)
                    .font(.title3)
                Text(mode.rawValue)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .asaSoftCream.opacity(0.7))
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.asaCoffeeBrown : Color.clear)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    EditorToolbar(viewModel: PhotoEditorViewModel())
}
