import SwiftUI
import AsaUIKit
import AsaPhotoStoryKit

/// ストーリーカードビュー
/// 一覧画面でストーリーの概要（サムネイル、タイトル、日付、ページ数）を表示する
struct StoryCardView: View {
    let story: PhotoStory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // サムネイル
            thumbnailView
                .frame(height: 140)
                .clipped()

            // 情報
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(story.title)
                        .font(.subheadline.bold())
                        .foregroundColor(AsaColors.darkSlate)
                        .lineLimit(1)

                    Spacer()

                    if story.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                HStack {
                    // 日付
                    Text(story.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)

                    Spacer()

                    // ページ数バッジ
                    HStack(spacing: 2) {
                        Image(systemName: "doc")
                            .font(.caption2)
                        Text("\(story.sortedPages.count)")
                            .font(.caption2.bold())
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AsaColors.softCream)
                    .clipShape(Capsule())
                }

                // テンプレートラベル
                HStack(spacing: 4) {
                    Image(systemName: story.template.iconName)
                        .font(.caption2)
                    Text(story.template.displayName)
                        .font(.caption2)
                }
                .foregroundColor(AsaColors.mutedSage)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailView: some View {
        // 最初のページの最初の写真要素をサムネイルに使用
        if let firstPage = story.sortedPages.first,
           let photoElement = firstPage.sortedElements.first(where: { $0.elementType == .photo }),
           let imageData = photoElement.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // プレースホルダーサムネイル
            ZStack {
                LinearGradient(
                    colors: [AsaColors.softCream, AsaColors.coffeeBrown.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 4) {
                    Image(systemName: story.template.iconName)
                        .font(.title)
                    Text(story.template.displayName)
                        .font(.caption2)
                }
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        StoryCardView(story: PhotoStory(title: "家族の夏休み", template: .travel, theme: .warm))
        StoryCardView(story: PhotoStory(title: "お誕生日会", template: .birthday, theme: .pastel))
    }
    .padding()
}
