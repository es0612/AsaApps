import SwiftUI
import AsaUIKit
import AsaPhotoStoryKit

/// エクスポートシート
/// フォーマット・解像度を選択してストーリーをエクスポートする
struct ExportSheetView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    let story: PhotoStory
    @State private var selectedFormat: ExportFormat = .image
    @State private var selectedResolution: ExportResolution = .high
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showProgress = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // フォーマット選択
                Section("エクスポート形式") {
                    Picker("形式", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Label(format.displayName, systemImage: format.iconName)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedFormat.formatDescription)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                // 解像度選択
                Section("解像度") {
                    Picker("解像度", selection: $selectedResolution) {
                        ForEach(ExportResolution.allCases, id: \.self) { resolution in
                            HStack {
                                Text(resolution.displayName)
                                Spacer()
                                Text(resolution.dimensionText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(resolution)
                        }
                    }
                    .pickerStyle(.inline)
                }

                // ストーリー情報
                Section("ストーリー情報") {
                    LabeledContent("タイトル", value: story.title)
                    LabeledContent("ページ数", value: "\(story.sortedPages.count)ページ")
                    LabeledContent("テンプレート", value: story.template.displayName)
                }

                // エクスポートボタン
                Section {
                    AsaButton(
                        title: "エクスポート",
                        action: { startExport() },
                        color: AsaColors.coffeeBrown,
                        isEnabled: !isExporting
                    )
                }
            }
            .navigationTitle("エクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
            .sheet(isPresented: $showProgress) {
                ExportProgressView(
                    progress: $exportProgress,
                    isExporting: $isExporting,
                    onComplete: { dismiss() },
                    onCancel: {
                        isExporting = false
                        showProgress = false
                    }
                )
            }
        }
    }

    // MARK: - Methods

    private func startExport() {
        isExporting = true
        exportProgress = 0
        showProgress = true
        // シミュレーション: エクスポートの進捗
        Task {
            for i in 1...10 {
                try? await Task.sleep(for: .milliseconds(300))
                await MainActor.run {
                    exportProgress = Double(i) / 10.0
                }
            }
            await MainActor.run {
                isExporting = false
            }
        }
    }
}

// MARK: - ExportFormat

enum ExportFormat: String, CaseIterable {
    case image
    case pdf
    case video

    var displayName: String {
        switch self {
        case .image: return "画像"
        case .pdf: return "PDF"
        case .video: return "動画"
        }
    }

    var iconName: String {
        switch self {
        case .image: return "photo"
        case .pdf: return "doc.richtext"
        case .video: return "film"
        }
    }

    var formatDescription: String {
        switch self {
        case .image: return "各ページをPNG画像として保存します"
        case .pdf: return "全ページを1つのPDFファイルにまとめます"
        case .video: return "スライドショー動画として書き出します"
        }
    }
}

// MARK: - ExportResolution

enum ExportResolution: String, CaseIterable {
    case standard
    case high
    case ultra

    var displayName: String {
        switch self {
        case .standard: return "標準"
        case .high: return "高画質"
        case .ultra: return "最高画質"
        }
    }

    var dimensionText: String {
        switch self {
        case .standard: return "1280x720"
        case .high: return "1920x1080"
        case .ultra: return "3840x2160"
        }
    }
}

#Preview {
    ExportSheetView(story: PhotoStory(title: "テスト", template: .blank, theme: .warm))
}
