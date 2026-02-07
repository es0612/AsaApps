import SwiftUI
import AsaUIKit
import AsaPhotoStoryKit

/// テンプレートギャラリー画面
/// テンプレートとテーマを選択し、新しいストーリーを作成する
struct TemplateGalleryView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: StoryTemplate = .blank
    @State private var selectedTheme: StoryTheme = .warm
    @State private var storyTitle = ""

    let onCreate: (PhotoStory) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    titleSection
                    templateSection
                    themeSection
                    createButton
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("新しいストーリー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タイトル")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            TextField("ストーリーのタイトルを入力", text: $storyTitle)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("テンプレート")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(StoryTemplate.allCases, id: \.self) { template in
                    TemplateCard(
                        template: template,
                        isSelected: selectedTemplate == template
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTemplate = template
                        }
                    }
                }
            }
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("テーマ")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StoryTheme.allCases, id: \.self) { theme in
                        ThemeChip(
                            theme: theme,
                            isSelected: selectedTheme == theme
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTheme = theme
                            }
                        }
                    }
                }
            }
        }
    }

    private var createButton: some View {
        AsaButton(
            title: "ストーリーを作成",
            action: {
                let title = storyTitle.isEmpty ? "新しいストーリー" : storyTitle
                let story = PhotoStory(
                    title: title,
                    template: selectedTemplate,
                    theme: selectedTheme
                )
                // テンプレートのデフォルトページ数分ページを追加
                for i in 0..<selectedTemplate.defaultPageCount {
                    let page = StoryPage(order: i)
                    page.story = story
                    story.pages.append(page)
                }
                onCreate(story)
            },
            color: AsaColors.coffeeBrown
        )
        .padding(.top, 8)
    }
}

// MARK: - TemplateCard

private struct TemplateCard: View {
    let template: StoryTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: template.iconName)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : AsaColors.coffeeBrown)

                Text(template.displayName)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : AsaColors.darkSlate)

                Text("\(template.defaultPageCount)ページ")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AsaColors.mutedSage)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? AsaColors.coffeeBrown : AsaColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AsaColors.mocha : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ThemeChip

private struct ThemeChip: View {
    let theme: StoryTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: theme.primaryColorHex))
                    .frame(width: 12, height: 12)
                Text(theme.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundColor(isSelected ? .white : AsaColors.darkSlate)
            .background(isSelected ? AsaColors.coffeeBrown : AsaColors.softCream)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? AsaColors.mocha : AsaColors.mutedSage.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    TemplateGalleryView { _ in }
}
