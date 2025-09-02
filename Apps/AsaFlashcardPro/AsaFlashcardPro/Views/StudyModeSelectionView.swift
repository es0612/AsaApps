import SwiftUI
import SwiftData

struct StudyModeSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var showingCategorySelection = false
    
    private var allFlashcards: [Flashcard] {
        categories.flatMap { $0.flashcards }
    }
    
    private var reviewFlashcards: [Flashcard] {
        allFlashcards.filter { $0.studyProgress.needsReview }
    }
    
    private var bookmarkedFlashcards: [Flashcard] {
        allFlashcards.filter { $0.isBookmarked }
    }
    
    private var hardFlashcards: [Flashcard] {
        allFlashcards.filter { $0.difficultyLevel == .hard }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    StudyHeaderView(
                        totalCards: allFlashcards.count,
                        reviewCards: reviewFlashcards.count,
                        studiedToday: todayStudiedCount
                    )
                    
                    // 学習モード選択
                    VStack(spacing: 16) {
                        Text("学習モードを選択")
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color("AsaDarkSlate"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            // 復習モード
                            NavigationLink(destination: StudyView(
                                flashcards: reviewFlashcards.shuffled(),
                                studyMode: .review
                            )) {
                                StudyModeCard(
                                    title: "復習",
                                    subtitle: "\\(reviewFlashcards.count)枚",
                                    description: "復習が必要な単語",
                                    icon: "clock.arrow.circlepath",
                                    color: "AsaMocha",
                                    isEnabled: !reviewFlashcards.isEmpty
                                ) { }
                            }
                            .disabled(reviewFlashcards.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                            
                            // カテゴリ別学習
                            StudyModeCard(
                                title: "カテゴリ",
                                subtitle: "\\(categories.count)個",
                                description: "カテゴリ別に学習",
                                icon: "folder.fill",
                                color: "AsaCoffeeBrown",
                                isEnabled: !categories.isEmpty
                            ) {
                                showingCategorySelection = true
                            }
                            
                            // お気に入り
                            NavigationLink(destination: StudyView(
                                flashcards: bookmarkedFlashcards.shuffled(),
                                studyMode: .bookmarked
                            )) {
                                StudyModeCard(
                                    title: "お気に入り",
                                    subtitle: "\\(bookmarkedFlashcards.count)枚",
                                    description: "お気に入りの単語",
                                    icon: "heart.fill",
                                    color: "AsaMutedSage",
                                    isEnabled: !bookmarkedFlashcards.isEmpty
                                ) { }
                            }
                            .disabled(bookmarkedFlashcards.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                            
                            // 難しい単語
                            NavigationLink(destination: StudyView(
                                flashcards: hardFlashcards.shuffled(),
                                studyMode: .hard
                            )) {
                                StudyModeCard(
                                    title: "難しい単語",
                                    subtitle: "\\(hardFlashcards.count)枚",
                                    description: "苦手な単語を集中",
                                    icon: "exclamationmark.triangle.fill",
                                    color: "AsaDarkSlate",
                                    isEnabled: !hardFlashcards.isEmpty
                                ) { }
                            }
                            .disabled(hardFlashcards.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                            
                            // ランダム学習
                            NavigationLink(destination: StudyView(
                                flashcards: allFlashcards.shuffled(),
                                studyMode: .random
                            )) {
                                StudyModeCard(
                                    title: "ランダム",
                                    subtitle: "\\(allFlashcards.count)枚",
                                    description: "すべてからランダム",
                                    icon: "shuffle",
                                    color: "AsaCoffeeBrown",
                                    isEnabled: !allFlashcards.isEmpty
                                ) { }
                            }
                            .disabled(allFlashcards.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                            
                            // クイックテスト
                            NavigationLink(destination: StudyView(
                                flashcards: Array(allFlashcards.shuffled().prefix(10)),
                                studyMode: .quick
                            )) {
                                StudyModeCard(
                                    title: "クイック",
                                    subtitle: "10枚",
                                    description: "短時間で学習",
                                    icon: "bolt.fill",
                                    color: "AsaMocha",
                                    isEnabled: allFlashcards.count >= 10
                                ) { }
                            }
                            .disabled(allFlashcards.count < 10)
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                        
                        // カテゴリ別クイックアクセス
                        if !categories.isEmpty {
                            CategoryQuickAccessView(categories: categories)
                        }
                    }
                }
            }
            .navigationTitle("学習")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCategorySelection) {
            CategorySelectionForStudyView()
        }
    }
    
    private var todayStudiedCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return allFlashcards.filter { flashcard in
            guard let lastStudied = flashcard.studyProgress.lastStudiedAt else { return false }
            return Calendar.current.startOfDay(for: lastStudied) == today
        }.count
    }
}

struct StudyHeaderView: View {
    let totalCards: Int
    let reviewCards: Int
    let studiedToday: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatsCard(title: "総単語数", value: "\\(totalCards)", icon: "doc.text.fill", color: "AsaCoffeeBrown")
                StatsCard(title: "復習待ち", value: "\\(reviewCards)", icon: "clock.fill", color: "AsaMocha")
                StatsCard(title: "今日の学習", value: "\\(studiedToday)", icon: "checkmark.circle.fill", color: "AsaMutedSage")
            }
            
            if reviewCards > 0 {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color("AsaMocha"))
                    
                    Text("\\(reviewCards)枚の単語が復習を待っています")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("AsaMocha").opacity(0.1))
                )
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("AsaSoftCream").opacity(0.2))
        )
        .padding(.horizontal)
    }
}

struct StudyModeCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(isEnabled ? Color(color) : Color("AsaDarkSlate").opacity(0.3))
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(isEnabled ? Color("AsaDarkSlate") : Color("AsaDarkSlate").opacity(0.5))
                    
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isEnabled ? Color(color) : Color("AsaDarkSlate").opacity(0.3))
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isEnabled ? Color("AsaDarkSlate").opacity(0.7) : Color("AsaDarkSlate").opacity(0.3))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(isEnabled ? 0.05 : 0.02), radius: 3, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}

struct CategoryQuickAccessView: View {
    let categories: [Category]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別学習")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories.prefix(5)) { category in
                        NavigationLink(destination: StudyView(
                            flashcards: category.flashcards.shuffled(),
                            studyMode: .category(category)
                        )) {
                            CategoryQuickCard(category: category) { }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CategoryQuickCard: View {
    let category: Category
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(Color(category.color))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(category.color).opacity(0.1))
                    )
                
                VStack(spacing: 2) {
                    Text(category.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color("AsaDarkSlate"))
                        .lineLimit(1)
                    
                    Text("\\(category.totalFlashcards)枚")
                        .font(.caption)
                        .foregroundColor(Color(category.color))
                }
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategorySelectionForStudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    NavigationLink(destination: StudyView(
                        flashcards: category.flashcards.shuffled(),
                        studyMode: .category(category)
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.title2)
                                .foregroundColor(Color(category.color))
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                
                                Text("\\(category.totalFlashcards)枚の単語")
                                    .font(.subheadline)
                                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                            }
                            
                            Spacer()
                            
                            if category.totalFlashcards > 0 {
                                Text("\\(Int(category.studyProgress * 100))%")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Color(category.color))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(category.flashcards.isEmpty)
                }
            }
            .navigationTitle("カテゴリを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
            }
        }
    }
}

#Preview {
    StudyModeSelectionView()
        .modelContainer(for: [Category.self, Flashcard.self, StudyProgress.self], inMemory: true)
}