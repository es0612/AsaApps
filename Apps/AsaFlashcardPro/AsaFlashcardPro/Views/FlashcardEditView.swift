import SwiftUI
import SwiftData

struct FlashcardEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let flashcard: Flashcard
    
    @State private var word = ""
    @State private var meaning = ""
    @State private var example = ""
    @State private var pronunciation = ""
    @State private var isBookmarked = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // プレビューカード
                FlashcardPreviewView(
                    word: word.isEmpty ? "単語" : word,
                    meaning: meaning.isEmpty ? "意味" : meaning,
                    category: flashcard.category ?? Category(name: "未分類", icon: "folder", color: "AsaCoffeeBrown")
                )
                
                VStack(spacing: 20) {
                    // 単語入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("単語 *")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        TextField("例: Apple", text: $word)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    // 意味入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("意味 *")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        TextField("例: りんご", text: $meaning)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    // 発音入力（オプション）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("発音（オプション）")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        TextField("例: æpl", text: $pronunciation)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    // 例文入力（オプション）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("例文（オプション）")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        TextField("例: I eat an apple every day.", text: $example, axis: .vertical)
                            .textFieldStyle(CustomTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // お気に入り設定
                    Toggle(isOn: $isBookmarked) {
                        HStack {
                            Image(systemName: isBookmarked ? "heart.fill" : "heart")
                                .foregroundColor(isBookmarked ? Color("AsaMocha") : Color("AsaDarkSlate").opacity(0.6))
                            
                            Text("お気に入りに追加")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(flashcard.category?.color ?? "AsaCoffeeBrown")))
                    
                    // 学習統計情報
                    StudyStatsView(flashcard: flashcard)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("単語を編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("変更を保存", action: saveChanges)
                        .disabled(!isValidInput)
                    
                    Button("学習データをリセット") {
                        resetStudyProgress()
                    }
                    
                    Button("単語を削除", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color(flashcard.category?.color ?? "AsaCoffeeBrown"))
                }
            }
        }
        .onAppear {
            loadFlashcardData()
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("単語を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteFlashcard()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この単語を削除します。学習データも失われます。")
        }
    }
    
    private var isValidInput: Bool {
        !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadFlashcardData() {
        word = flashcard.word
        meaning = flashcard.meaning
        example = flashcard.example ?? ""
        pronunciation = flashcard.pronunciation ?? ""
        isBookmarked = flashcard.isBookmarked
    }
    
    private func saveChanges() {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMeaning = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample = example.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPronunciation = pronunciation.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedWord.isEmpty && !trimmedMeaning.isEmpty else {
            errorMessage = "単語と意味を入力してください。"
            showingError = true
            return
        }
        
        flashcard.word = trimmedWord
        flashcard.meaning = trimmedMeaning
        flashcard.example = trimmedExample.isEmpty ? nil : trimmedExample
        flashcard.pronunciation = trimmedPronunciation.isEmpty ? nil : trimmedPronunciation
        flashcard.isBookmarked = isBookmarked
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "変更の保存に失敗しました: \\(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func resetStudyProgress() {
        flashcard.studyProgress.correctAnswers = 0
        flashcard.studyProgress.totalAnswers = 0
        flashcard.studyProgress.streak = 0
        flashcard.studyProgress.isStudied = false
        flashcard.studyProgress.lastStudiedAt = nil
        flashcard.studyProgress.nextReviewDate = nil
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "学習データのリセットに失敗しました: \\(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func deleteFlashcard() {
        if let category = flashcard.category,
           let index = category.flashcards.firstIndex(where: { $0.id == flashcard.id }) {
            category.flashcards.remove(at: index)
        }
        
        modelContext.delete(flashcard)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "単語の削除に失敗しました: \\(error.localizedDescription)"
            showingError = true
        }
    }
}

struct StudyStatsView: View {
    let flashcard: Flashcard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学習統計")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            VStack(spacing: 8) {
                HStack {
                    Text("総回答数:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text("\\(flashcard.studyProgress.totalAnswers)回")
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                
                HStack {
                    Text("正解数:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text("\\(flashcard.studyProgress.correctAnswers)回")
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                
                HStack {
                    Text("正解率:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text("\\(Int(flashcard.studyProgress.correctRate * 100))%")
                        .fontWeight(.medium)
                        .foregroundColor(Color(flashcard.category?.color ?? "AsaCoffeeBrown"))
                }
                
                HStack {
                    Text("連続正解:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text("\\(flashcard.studyProgress.streak)回")
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaMocha"))
                }
                
                HStack {
                    Text("難易度:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text(flashcard.difficultyLevel.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(Color(flashcard.difficultyLevel.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(flashcard.difficultyLevel.color).opacity(0.1))
                        )
                }
                
                if let lastStudied = flashcard.studyProgress.lastStudiedAt {
                    HStack {
                        Text("最終学習:")
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                        Spacer()
                        Text(lastStudied, style: .relative)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                }
                
                if let nextReview = flashcard.studyProgress.nextReviewDate {
                    HStack {
                        Text("次回復習:")
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                        Spacer()
                        Text(nextReview, style: .date)
                            .fontWeight(.medium)
                            .foregroundColor(flashcard.studyProgress.needsReview ? Color("AsaMocha") : Color("AsaDarkSlate"))
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("AsaSoftCream").opacity(0.2))
        )
    }
}

#Preview {
    let container = try! ModelContainer(for: Category.self, Flashcard.self, StudyProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let category = Category(name: "英語基礎", icon: "textbook", color: "AsaCoffeeBrown")
    let flashcard = Flashcard(word: "Apple", meaning: "りんご", example: "I eat an apple every day.", category: category)
    container.mainContext.insert(category)
    container.mainContext.insert(flashcard)
    
    return NavigationView {
        FlashcardEditView(flashcard: flashcard)
            .modelContainer(container)
    }
}