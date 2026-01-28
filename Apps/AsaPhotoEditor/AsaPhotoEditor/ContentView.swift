import SwiftUI
import PhotosUI
import SwiftData

// MARK: - ContentView
struct ContentView: View {
    // MARK: - Properties

    @State private var viewModel = PhotoEditorViewModel()
    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color.asaDarkSlate
                    .ignoresSafeArea()

                if viewModel.originalImage != nil {
                    // エディタービュー
                    EditorMainView(viewModel: viewModel)
                } else {
                    // 画像選択ビュー
                    ImagePickerPromptView(viewModel: viewModel)
                }

                // 処理中オーバーレイ
                if viewModel.isProcessing {
                    ProcessingOverlay()
                }
            }
            .navigationTitle("AsaPhotoEditor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.asaMocha, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.originalImage != nil {
                        Button {
                            viewModel.showingProjectList = true
                        } label: {
                            Image(systemName: "folder")
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.originalImage != nil {
                        Menu {
                            Button {
                                viewModel.saveProject(to: modelContext)
                            } label: {
                                Label("プロジェクトを保存", systemImage: "square.and.arrow.down")
                            }

                            Button {
                                Task {
                                    await viewModel.saveToPhotoLibrary()
                                }
                            } label: {
                                Label("写真に保存", systemImage: "photo.on.rectangle")
                            }

                            Button {
                                viewModel.showingExportSheet = true
                            } label: {
                                Label("エクスポート", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            Button(role: .destructive) {
                                viewModel.resetAllEdits()
                            } label: {
                                Label("すべてリセット", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .onChange(of: viewModel.selectedPhotoItem) { _, _ in
                Task {
                    await viewModel.loadSelectedPhoto()
                }
            }
            .alert("エラー", isPresented: $viewModel.showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラー")
            }
            .alert("保存完了", isPresented: $viewModel.showingSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("正常に保存されました")
            }
            .sheet(isPresented: $viewModel.showingProjectList) {
                ProjectListView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingExportSheet) {
                ExportSheetView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - ImagePickerPromptView
struct ImagePickerPromptView: View {
    @Bindable var viewModel: PhotoEditorViewModel

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.asaSoftCream)

            Text("写真を選択して編集を開始")
                .font(.title2)
                .foregroundColor(.asaSoftCream)

            PhotosPicker(
                selection: $viewModel.selectedPhotoItem,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text("写真を選択")
                }
                .font(.title3.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.asaCoffeeBrown)
                .cornerRadius(12)
                .shadow(radius: 3)
            }

            Button {
                viewModel.showingProjectList = true
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("プロジェクトを開く")
                }
                .font(.body)
                .foregroundColor(.asaSoftCream)
            }
        }
    }
}

// MARK: - ProcessingOverlay
struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 15) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("処理中...")
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.asaDarkSlate.opacity(0.9))
            .cornerRadius(15)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(for: EditProject.self, inMemory: true)
}
