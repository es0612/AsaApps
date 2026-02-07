import SwiftUI
import AsaUIKit
import AsaPhotoStoryKit

/// ストーリー設定画面
/// ストーリーのメタデータ（タイトル、説明、テンプレート、テーマ等）を編集する
struct StorySettingsView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Bindable var story: PhotoStory
    @State private var tagInput = ""
    @State private var descriptionText = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報
                Section("基本情報") {
                    TextField("タイトル", text: $story.title)
                    TextField("説明", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                }

                // テンプレート・テーマ
                Section("デザイン") {
                    Picker("テンプレート", selection: Binding(
                        get: { story.template },
                        set: { story.template = $0 }
                    )) {
                        ForEach(StoryTemplate.allCases, id: \.self) { template in
                            Label(template.displayName, systemImage: template.iconName)
                                .tag(template)
                        }
                    }

                    Picker("テーマ", selection: Binding(
                        get: { story.theme },
                        set: { story.theme = $0 }
                    )) {
                        ForEach(StoryTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName)
                                .tag(theme)
                        }
                    }
                }

                // タグ
                Section("タグ") {
                    // 既存タグ表示
                    let currentTags = story.tags
                    if !currentTags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(currentTags, id: \.self) { tag in
                                TagChip(tag: tag) {
                                    var tags = story.tags
                                    tags.removeAll { $0 == tag }
                                    story.tags = tags
                                }
                            }
                        }
                    }

                    HStack {
                        TextField("タグを追加", text: $tagInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addTag()
                            }
                        Button {
                            addTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                        .disabled(tagInput.isEmpty)
                    }
                }

                // お気に入り
                Section {
                    Toggle(isOn: $story.isFavorite) {
                        Label("お気に入り", systemImage: story.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(story.isFavorite ? .red : .primary)
                    }
                    .tint(AsaColors.coffeeBrown)
                }

                // メタ情報
                Section("情報") {
                    LabeledContent("作成日", value: story.createdAt.formatted(date: .long, time: .shortened))
                    LabeledContent("更新日", value: story.updatedAt.formatted(date: .long, time: .shortened))
                    LabeledContent("ページ数", value: "\(story.sortedPages.count)ページ")
                }
            }
            .navigationTitle("ストーリー設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        story.storyDescription = descriptionText.isEmpty ? nil : descriptionText
                        story.updatedAt = Date()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
            .onAppear {
                descriptionText = story.storyDescription ?? ""
            }
        }
    }

    // MARK: - Methods

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var currentTags = story.tags
        guard !currentTags.contains(trimmed) else { return }
        currentTags.append(trimmed)
        story.tags = currentTags
        tagInput = ""
    }
}

// MARK: - TagChip

private struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption.bold())
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundColor(AsaColors.darkSlate)
        .background(AsaColors.softCream)
        .clipShape(Capsule())
    }
}

// MARK: - FlowLayout

/// タグを横に並べて折り返すレイアウト
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    StorySettingsView(story: PhotoStory(title: "テスト", template: .blank, theme: .warm))
}
