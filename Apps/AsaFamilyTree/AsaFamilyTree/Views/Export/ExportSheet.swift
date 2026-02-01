import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

struct ExportSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyTreeViewModel.self) private var viewModel

    // MARK: - State

    @State private var selectedFormat: ExportFormat = .png
    @State private var includeStatistics = true
    @State private var isExporting = false
    @State private var exportedImage: UIImage?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 形式選択
                Section("エクスポート形式") {
                    Picker("形式", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // オプション
                Section("オプション") {
                    Toggle("統計情報を含める", isOn: $includeStatistics)
                }

                // プレビュー
                Section("プレビュー") {
                    if let tree = viewModel.currentTree {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tree.name)
                                .font(.headline)

                            Text("\(tree.memberCount)人のメンバー")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if includeStatistics, let stats = viewModel.statistics {
                                Divider()

                                HStack(spacing: 16) {
                                    StatPreviewItem(label: "世代数", value: "\(stats.generationCount)")
                                    StatPreviewItem(label: "存命", value: "\(stats.aliveMembers)")
                                    StatPreviewItem(label: "故人", value: "\(stats.deceasedMembers)")
                                }
                            }
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // エラーメッセージ
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("エクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("エクスポート") {
                        exportFamilyTree()
                    }
                    .disabled(isExporting || viewModel.currentTree == nil)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = exportedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // MARK: - Methods

    private func exportFamilyTree() {
        guard let tree = viewModel.currentTree else { return }

        isExporting = true
        errorMessage = nil

        Task {
            do {
                // 簡易的な画像生成（実際のアプリではより高度な実装が必要）
                let renderer = ImageRenderer(content: exportPreview(tree: tree))
                renderer.scale = 3.0 // Retina対応

                if let image = renderer.uiImage {
                    exportedImage = image
                    showingShareSheet = true
                } else {
                    throw FamilyTreeError.exportFailed("画像の生成に失敗しました")
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isExporting = false
        }
    }

    @MainActor
    private func exportPreview(tree: FamilyTree) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                Image(systemName: "tree.fill")
                    .font(.largeTitle)
                    .foregroundStyle(AsaColors.coffeeBrown)

                VStack(alignment: .leading) {
                    Text(tree.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("作成日: \(tree.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // メンバー数
            Text("\(tree.memberCount)人のメンバー")
                .font(.headline)

            // 統計（オプション）
            if includeStatistics, let stats = viewModel.statistics {
                VStack(alignment: .leading, spacing: 8) {
                    Text("統計情報")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            Text("世代数: \(stats.generationCount)")
                            Text("存命: \(stats.aliveMembers)人")
                            Text("故人: \(stats.deceasedMembers)人")
                        }
                        .font(.caption)

                        VStack(alignment: .leading) {
                            Text("男性: \(stats.maleCount)人")
                            Text("女性: \(stats.femaleCount)人")
                            if stats.otherGenderCount > 0 {
                                Text("その他: \(stats.otherGenderCount)人")
                            }
                        }
                        .font(.caption)
                    }
                }
            }

            Spacer()

            // フッター
            HStack {
                Spacer()
                Text("AsaFamilyTree で作成")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 400, height: 300)
        .background(Color.white)
    }
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable {
    case png
    case pdf

    var displayName: String {
        switch self {
        case .png: return "PNG画像"
        case .pdf: return "PDF"
        }
    }
}

// MARK: - Stat Preview Item

struct StatPreviewItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ExportSheet()
        .environment(FamilyTreeViewModel())
}
