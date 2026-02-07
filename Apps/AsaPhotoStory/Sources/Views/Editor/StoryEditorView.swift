import SwiftUI
import SwiftData
import AsaUIKit
import AsaPhotoStoryKit

/// メイン編集画面
/// ストーリーのページを編集するための中心的な画面
struct StoryEditorView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var story: PhotoStory
    @State private var currentPageIndex = 0
    @State private var selectedElementId: UUID?
    @State private var showPhotoPicker = false
    @State private var showTextEditor = false
    @State private var showCaptionSuggestion = false
    @State private var showExport = false
    @State private var showSettings = false
    @State private var showPreview = false

    // MARK: - Computed

    private var currentPage: StoryPage? {
        let sorted = story.sortedPages
        guard currentPageIndex >= 0, currentPageIndex < sorted.count else { return nil }
        return sorted[currentPageIndex]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ページキャンバス
            if let currentPage {
                PageCanvasView(
                    page: currentPage,
                    selectedElementId: $selectedElementId
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
            } else {
                emptyPagePlaceholder
            }

            Divider()

            // ページサムネイルストリップ
            PageThumbnailStrip(
                pages: story.sortedPages,
                currentPageIndex: $currentPageIndex,
                onAddPage: { addPage() },
                onDeletePage: { index in deletePage(at: index) }
            )

            Divider()

            // 編集ツールバー
            EditorToolbar(
                onAddPhoto: { showPhotoPicker = true },
                onAddText: { showTextEditor = true },
                onAddSticker: { addStickerElement() },
                onAddDrawing: { /* 描画モード - 将来実装 */ },
                onChangeLayout: { /* レイアウト変更 - 将来実装 */ }
            )
        }
        .background(AsaColors.softCream.opacity(0.2))
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showPreview = true
                } label: {
                    Image(systemName: "play.fill")
                }

                Menu {
                    Button {
                        showSettings = true
                    } label: {
                        Label("設定", systemImage: "gear")
                    }
                    Button {
                        showExport = true
                    } label: {
                        Label("エクスポート", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerSheetView { imageDataArray in
                guard let page = currentPage else { return }
                for imageData in imageDataArray {
                    let maxZ = page.elements.map(\.zOrder).max() ?? -1
                    let element = StoryElement.photoElement(imageData: imageData, zOrder: maxZ + 1)
                    element.page = page
                    page.elements.append(element)
                }
                story.updatedAt = Date()
            }
        }
        .sheet(isPresented: $showTextEditor) {
            TextEditorSheetView { text, fontName, fontSize, colorHex in
                guard let page = currentPage else { return }
                let maxZ = page.elements.map(\.zOrder).max() ?? -1
                let element = StoryElement.textElement(
                    text: text,
                    fontName: fontName,
                    fontSize: fontSize,
                    colorHex: colorHex,
                    zOrder: maxZ + 1
                )
                element.page = page
                page.elements.append(element)
                story.updatedAt = Date()
            }
        }
        .sheet(isPresented: $showCaptionSuggestion) {
            if let elementId = selectedElementId {
                CaptionSuggestionView(elementId: elementId) { caption in
                    if let page = currentPage,
                       let element = page.elements.first(where: { $0.id == elementId }) {
                        element.captionText = caption
                        story.updatedAt = Date()
                    }
                }
            }
        }
        .sheet(isPresented: $showExport) {
            ExportSheetView(story: story)
        }
        .sheet(isPresented: $showSettings) {
            StorySettingsView(story: story)
        }
        .fullScreenCover(isPresented: $showPreview) {
            StoryPreviewView(story: story)
        }
    }

    // MARK: - Subviews

    private var emptyPagePlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(AsaColors.mutedSage)

            Text("ページを追加して始めましょう")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            AsaButton(
                title: "最初のページを追加",
                action: { addPage() },
                color: AsaColors.coffeeBrown
            )
            .frame(width: 220)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Methods

    private func addPage() {
        let nextOrder = story.pages.map(\.order).max().map { $0 + 1 } ?? 0
        let page = StoryPage(order: nextOrder)
        page.story = story
        story.pages.append(page)
        currentPageIndex = story.sortedPages.count - 1
        story.updatedAt = Date()
    }

    private func deletePage(at index: Int) {
        let sorted = story.sortedPages
        guard index >= 0, index < sorted.count, sorted.count > 1 else { return }
        let page = sorted[index]
        story.pages.removeAll { $0.id == page.id }
        modelContext.delete(page)
        // order再設定
        for (i, p) in story.sortedPages.enumerated() {
            p.order = i
        }
        if currentPageIndex >= story.sortedPages.count {
            currentPageIndex = max(0, story.sortedPages.count - 1)
        }
        story.updatedAt = Date()
    }

    private func addStickerElement() {
        guard let page = currentPage else { return }
        let stickerNames = ["star.fill", "heart.fill", "sun.max.fill", "moon.fill", "cloud.fill", "sparkles"]
        let randomName = stickerNames.randomElement() ?? "star.fill"
        let maxZ = page.elements.map(\.zOrder).max() ?? -1
        let element = StoryElement.stickerElement(name: randomName, zOrder: maxZ + 1)
        element.page = page
        page.elements.append(element)
        story.updatedAt = Date()
    }
}

#Preview {
    NavigationStack {
        StoryEditorView(story: PhotoStory(title: "テストストーリー", template: .blank, theme: .warm))
    }
    .modelContainer(for: PhotoStory.self, inMemory: true)
}
