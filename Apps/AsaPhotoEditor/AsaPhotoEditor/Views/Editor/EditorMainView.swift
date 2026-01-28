import SwiftUI
import PhotosUI

// MARK: - EditorMainView
struct EditorMainView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // プレビューエリア
            ImagePreviewView(viewModel: viewModel)

            // ツールバー
            EditorToolbar(viewModel: viewModel)

            // モード別パネル
            EditorPanelView(viewModel: viewModel)
        }
    }
}

// MARK: - EditorPanelView
struct EditorPanelView: View {
    @Bindable var viewModel: PhotoEditorViewModel

    var body: some View {
        Group {
            switch viewModel.currentMode {
            case .adjustment:
                AdjustmentPanelView(viewModel: viewModel)
            case .filter:
                FilterPanelView(viewModel: viewModel)
            case .crop:
                CropPanelView(viewModel: viewModel)
            case .text:
                TextPanelView(viewModel: viewModel)
            case .drawing:
                DrawingPanelView(viewModel: viewModel)
            }
        }
        .frame(height: 180)
        .background(Color.asaDarkSlate.opacity(0.95))
    }
}

// MARK: - Preview
#Preview {
    EditorMainView(viewModel: PhotoEditorViewModel())
}
