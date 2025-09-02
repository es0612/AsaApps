import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let category: Category
    @State private var showingAddFlashcard = false
    @State private var showingEditCategory = false
    @State private var searchText = ""
    @State private var selectedSortOption: SortOption = .dateCreated
    @State private var showingDeleteAlert = false
    @State private var selectedFlashcardForStudy: Flashcard?
    @State private var showingAllCardsStudy = false
    
    private var filteredFlashcards: [Flashcard] {
        var flashcards = category.flashcards
        
        if !searchText.isEmpty {
            flashcards = flashcards.filter {
                $0.word.localizedCaseInsensitiveContains(searchText) ||
                $0.meaning.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedSortOption {
        case .dateCreated:
            return flashcards.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            return flashcards.sorted { $0.word < $1.word }
        case .progress:
            return flashcards.sorted { $0.studyProgress.correctRate > $1.studyProgress.correctRate }
        case .difficulty:
            return flashcards.sorted { $0.difficultyLevel.rawValue < $1.difficultyLevel.rawValue }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case dateCreated = "作成日"
        case alphabetical = "五十音順"
        case progress = "進捗率"
        case difficulty = "難易度"
    }
    
    var body: some View {
        VStack {
            // カテゴリ統計ヘッダー
            CategoryStatsView(categories: [category], timeRange: .week)
            
            // フラッシュカードリスト
            List {
                ForEach(filteredFlashcards) { flashcard in
                    NavigationLink(destination: FlashcardEditView(flashcard: flashcard)) {
                        FlashcardRowView(flashcard: flashcard)
                    }
                    .listRowBackground(Color("AsaSoftCream").opacity(0.2))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("削除", role: .destructive) {
                            deleteFlashcard(flashcard)
                        }
                        
                        Button("学習") {
                            selectedFlashcardForStudy = flashcard
                        }
                        .tint(Color(category.color))
                    }
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "単語を検索")
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            selectedSortOption = option
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(Color(category.color))
                }
                
                Menu {
                    Button("カテゴリを編集") {
                        showingEditCategory = true
                    }
                    
                    Button("カテゴリを削除", role: .destructive) {
                        showingDeleteAlert = true
                    }
                    
                    Button("すべて学習") {
                        showingAllCardsStudy = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color(category.color))
                }
                
                Button(action: { showingAddFlashcard = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(category.color))
                }
            }
        }
        .sheet(isPresented: $showingAddFlashcard) {
            AddFlashcardView(category: category)
        }
        .sheet(isPresented: $showingEditCategory) {
            EditCategoryView(category: category)
        }
        .alert("カテゴリを削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteCategoryAndFlashcards()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("このカテゴリとすべての単語が削除されます。この操作は元に戻せません。")
        }
        .background(
            Group {
                // 単一カード学習用NavigationLink
                if let flashcard = selectedFlashcardForStudy {
                    NavigationLink(
                        destination: StudyView(
                            flashcards: [flashcard],
                            studyMode: .category(category)
                        ),
                        isActive: Binding(
                            get: { selectedFlashcardForStudy != nil },
                            set: { _ in selectedFlashcardForStudy = nil }
                        )
                    ) {
                        EmptyView()
                    }
                }
                
                // カテゴリ全体学習用NavigationLink
                NavigationLink(
                    destination: StudyView(
                        flashcards: category.flashcards.shuffled(),
                        studyMode: .category(category)
                    ),
                    isActive: $showingAllCardsStudy
                ) {
                    EmptyView()
                }
            }
        )
    }
    
    private func deleteFlashcard(_ flashcard: Flashcard) {
        withAnimation {
            if let index = category.flashcards.firstIndex(where: { $0.id == flashcard.id }) {
                category.flashcards.remove(at: index)
            }
            modelContext.delete(flashcard)
            
            do {
                try modelContext.save()
            } catch {
                print("フラッシュカードの削除に失敗しました: \\(error)")
            }
        }
    }
    
    private func deleteCategoryAndFlashcards() {
        // すべてのフラッシュカードを削除
        for flashcard in category.flashcards {
            modelContext.delete(flashcard)
        }
        
        // カテゴリを削除
        modelContext.delete(category)
        
        do {
            try modelContext.save()
        } catch {
            print("カテゴリの削除に失敗しました: \\(error)")
        }
    }
}



struct StatItem: View {
    let title: String
    let value: String
    let color: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(Color(color))
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlashcardRowView: View {
    let flashcard: Flashcard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flashcard.word)
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Text(flashcard.meaning)
                        .font(.subheadline)
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    
                    if let example = flashcard.example, !example.isEmpty {
                        Text(example)
                            .font(.caption)
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.5))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // 難易度レベル
                    Text(flashcard.difficultyLevel.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color(flashcard.difficultyLevel.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(flashcard.difficultyLevel.color).opacity(0.1))
                        )
                    
                    // お気に入り
                    if flashcard.isBookmarked {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(Color("AsaMocha"))
                    }
                    
                    // 正解率
                    if flashcard.studyProgress.totalAnswers > 0 {
                        Text("\\(Int(flashcard.studyProgress.correctRate * 100))%")
                            .font(.caption.weight(.medium))
                            .foregroundColor(Color(flashcard.category?.color ?? "AsaCoffeeBrown"))
                    }
                }
            }
            
            // 学習進捗バー
            if flashcard.studyProgress.totalAnswers > 0 {
                ProgressView(value: flashcard.studyProgress.correctRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(flashcard.category?.color ?? "AsaCoffeeBrown")))
                    .scaleEffect(y: 0.6)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let container = try! ModelContainer(for: Category.self, Flashcard.self, StudyProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let category = Category(name: "英語基礎", icon: "textbook", color: "AsaCoffeeBrown")
    container.mainContext.insert(category)
    
    return NavigationView {
        CategoryDetailView(category: category)
            .modelContainer(container)
    }
}