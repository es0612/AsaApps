import SwiftUI
import AsaUIKit
import AsaPhotoStoryKit

/// ページサムネイルストリップ
/// 横スクロールでページの一覧をサムネイル表示し、選択・追加・削除を提供する
struct PageThumbnailStrip: View {
    // MARK: - Properties

    let pages: [StoryPage]
    @Binding var currentPageIndex: Int
    let onAddPage: () -> Void
    let onDeletePage: (Int) -> Void

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    thumbnailCard(for: page, at: index)
                }

                // ページ追加ボタン
                addPageButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 100)
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    private func thumbnailCard(for page: StoryPage, at index: Int) -> some View {
        let isSelected = index == currentPageIndex

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentPageIndex = index
            }
        } label: {
            VStack(spacing: 4) {
                // サムネイル
                RoundedRectangle(cornerRadius: 6)
                    .fill(thumbnailBackground(for: page))
                    .frame(width: 60, height: 45)
                    .overlay {
                        Text("\(index + 1)")
                            .font(.caption2.bold())
                            .foregroundColor(isSelected ? .white : AsaColors.mutedSage)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? AsaColors.coffeeBrown : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? AsaColors.coffeeBrown.opacity(0.3) : .clear, radius: 4)

                Text("P\(index + 1)")
                    .font(.caption2)
                    .foregroundColor(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDeletePage(index)
            } label: {
                Label("ページを削除", systemImage: "trash")
            }
            .disabled(pages.count <= 1)
        }
    }

    private var addPageButton: some View {
        Button(action: onAddPage) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AsaColors.coffeeBrown, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .frame(width: 60, height: 45)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(AsaColors.coffeeBrown)
                    }

                Text("追加")
                    .font(.caption2)
                    .foregroundColor(AsaColors.coffeeBrown)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func thumbnailBackground(for page: StoryPage) -> some ShapeStyle {
        if let hex = page.backgroundColorHex {
            return AnyShapeStyle(Color(hex: hex))
        }
        return AnyShapeStyle(AsaColors.softCream.opacity(0.5))
    }
}

#Preview {
    PageThumbnailStrip(
        pages: [
            StoryPage(order: 0),
            StoryPage(order: 1),
            StoryPage(order: 2),
        ],
        currentPageIndex: .constant(0),
        onAddPage: {},
        onDeletePage: { _ in }
    )
}
