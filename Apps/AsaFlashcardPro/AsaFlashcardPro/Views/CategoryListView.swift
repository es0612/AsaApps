import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.createdAt, order: .reverse) private var categories: [Category]
    @State private var showingAddCategory = false
    @State private var searchText = ""
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // ヘッダー統計
                HeaderStatsView(categories: categories)
                
                // カテゴリリスト
                List {
                    ForEach(filteredCategories) { category in
                        NavigationLink(destination: CategoryDetailView(category: category)) {
                            CategoryRowView(category: category)
                        }
                        .listRowBackground(Color("AsaSoftCream").opacity(0.3))
                    }
                    .onDelete(perform: deleteCategories)
                }
                .listStyle(PlainListStyle())
                .searchable(text: $searchText, prompt: "カテゴリを検索")
            }
            .navigationTitle("AsaFlashcardPro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let category = filteredCategories[index]
                
                // カテゴリに属するフラッシュカードも削除
                for flashcard in category.flashcards {
                    modelContext.delete(flashcard)
                }
                
                modelContext.delete(category)
            }
            
            do {
                try modelContext.save()
            } catch {
                print("カテゴリの削除に失敗しました: \\(error)")
            }
        }
    }
}

struct HeaderStatsView: View {
    let categories: [Category]
    
    private var totalFlashcards: Int {
        categories.reduce(0) { $0 + $1.totalFlashcards }
    }
    
    private var totalStudied: Int {
        categories.reduce(0) { $0 + $1.studiedFlashcards }
    }
    
    private var overallProgress: Double {
        guard totalFlashcards > 0 else { return 0.0 }
        return Double(totalStudied) / Double(totalFlashcards)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatsCard(title: "カテゴリ", value: "\\(categories.count)", icon: "folder.fill", color: "AsaCoffeeBrown")
                StatsCard(title: "単語", value: "\\(totalFlashcards)", icon: "doc.text.fill", color: "AsaMocha")
                StatsCard(title: "学習済み", value: "\\(totalStudied)", icon: "checkmark.circle.fill", color: "AsaMutedSage")
            }
            
            if totalFlashcards > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("全体の進捗")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        Spacer()
                        Text("\\(Int(overallProgress * 100))%")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    ProgressView(value: overallProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                        .scaleEffect(y: 1.5)
                }
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

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(color))
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: 15) {
            // カテゴリアイコン
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(Color(category.color))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("\\(category.totalFlashcards)枚の単語")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                
                if category.totalFlashcards > 0 {
                    ProgressView(value: category.studyProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(category.color)))
                        .scaleEffect(y: 0.8)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if category.totalFlashcards > 0 {
                    Text("\\(Int(category.studyProgress * 100))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(category.color))
                }
                
                Text("\\(category.studiedFlashcards)/\\(category.totalFlashcards)")
                    .font(.caption)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CategoryListView()
        .modelContainer(for: [Category.self, Flashcard.self, StudyProgress.self], inMemory: true)
}