import SwiftUI
import SwiftData
import AsaUIKit
import AsaPhotoStoryKit

/// ストーリー一覧画面
/// LazyVGridでストーリーカードを表示し、検索・フィルター・新規作成を提供
struct StoryListView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PhotoStory.updatedAt, order: .reverse) private var stories: [PhotoStory]
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var showTemplateGallery = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    // MARK: - Computed

    private var filteredStories: [PhotoStory] {
        var result = stories
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if filteredStories.isEmpty {
                EmptyStateView {
                    showTemplateGallery = true
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredStories) { story in
                            NavigationLink(value: story) {
                                StoryCardView(story: story)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteStory(story)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                                Button {
                                    toggleFavorite(story)
                                } label: {
                                    Label(
                                        story.isFavorite ? "お気に入り解除" : "お気に入り",
                                        systemImage: story.isFavorite ? "heart.slash" : "heart"
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }

            // FAB - 新規作成ボタン
            Button {
                showTemplateGallery = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(AsaColors.coffeeBrown)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("フォトストーリー")
        .searchable(text: $searchText, prompt: "ストーリーを検索")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        showFavoritesOnly.toggle()
                    }
                } label: {
                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        .foregroundColor(showFavoritesOnly ? .red : AsaColors.coffeeBrown)
                }
            }
        }
        .navigationDestination(for: PhotoStory.self) { story in
            StoryEditorView(story: story)
        }
        .sheet(isPresented: $showTemplateGallery) {
            TemplateGalleryView { newStory in
                modelContext.insert(newStory)
                showTemplateGallery = false
            }
        }
    }

    // MARK: - Methods

    private func deleteStory(_ story: PhotoStory) {
        withAnimation {
            modelContext.delete(story)
        }
    }

    private func toggleFavorite(_ story: PhotoStory) {
        story.isFavorite.toggle()
        story.updatedAt = Date()
    }
}

#Preview {
    NavigationStack {
        StoryListView()
    }
    .modelContainer(for: PhotoStory.self, inMemory: true)
}
