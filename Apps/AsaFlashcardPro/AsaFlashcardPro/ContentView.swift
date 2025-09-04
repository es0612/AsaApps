import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CategoryListView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("カテゴリ")
                }
                .tag(0)
            
            StudyModeSelectionView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("学習")
                }
                .tag(1)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
                .tag(3)
        }
        .accentColor(Color("AsaCoffeeBrown"))
        .onAppear {
            setupInitialDataIfNeeded()
        }
    }
    
    private func setupInitialDataIfNeeded() {
        // 初回起動時のみサンプルデータを作成
        if categories.isEmpty {
            createSampleData()
        }
    }
    
    private func createSampleData() {
        // 英語基礎カテゴリ
        let englishCategory = Category(name: "英語基礎", icon: "textbook", color: "AsaCoffeeBrown")
        modelContext.insert(englishCategory)
        
        let englishFlashcards = [
            Flashcard(word: "Apple", meaning: "りんご", example: "I eat an apple every day.", category: englishCategory),
            Flashcard(word: "Book", meaning: "本", example: "This is a good book.", category: englishCategory),
            Flashcard(word: "Cat", meaning: "猫", example: "The cat is sleeping.", category: englishCategory),
            Flashcard(word: "Dog", meaning: "犬", example: "My dog likes to play.", category: englishCategory),
            Flashcard(word: "House", meaning: "家", example: "I live in a big house.", category: englishCategory)
        ]
        
        for flashcard in englishFlashcards {
            modelContext.insert(flashcard)
            englishCategory.flashcards.append(flashcard)
        }
        
        // 日本語基礎カテゴリ
        let japaneseCategory = Category(name: "日本語基礎", icon: "character.book.closed", color: "AsaMocha")
        modelContext.insert(japaneseCategory)
        
        let japaneseFlashcards = [
            Flashcard(word: "さくら", meaning: "桜", example: "春にさくらが咲きます。", category: japaneseCategory),
            Flashcard(word: "やま", meaning: "山", example: "高いやまに登りました。", category: japaneseCategory),
            Flashcard(word: "うみ", meaning: "海", example: "夏にうみで泳ぎました。", category: japaneseCategory)
        ]
        
        for flashcard in japaneseFlashcards {
            modelContext.insert(flashcard)
            japaneseCategory.flashcards.append(flashcard)
        }
        
        // プログラミング用語カテゴリ
        let programmingCategory = Category(name: "プログラミング用語", icon: "laptopcomputer", color: "AsaMutedSage")
        modelContext.insert(programmingCategory)
        
        let programmingFlashcards = [
            Flashcard(word: "Variable", meaning: "変数", example: "let variable = 'Hello'", category: programmingCategory),
            Flashcard(word: "Function", meaning: "関数", example: "func myFunction() { }", category: programmingCategory),
            Flashcard(word: "Array", meaning: "配列", example: "let array = [1, 2, 3]", category: programmingCategory),
            Flashcard(word: "Loop", meaning: "ループ", example: "for item in array { }", category: programmingCategory)
        ]
        
        for flashcard in programmingFlashcards {
            modelContext.insert(flashcard)
            programmingCategory.flashcards.append(flashcard)
        }
        
        // データを保存
        do {
            try modelContext.save()
        } catch {
            print("サンプルデータの作成に失敗しました: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Category.self, Flashcard.self, StudyProgress.self], inMemory: true)
}
