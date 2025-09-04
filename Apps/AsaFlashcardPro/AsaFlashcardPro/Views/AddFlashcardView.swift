import SwiftUI
import SwiftData

struct AddFlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    
    @State private var word = ""
    @State private var meaning = ""
    @State private var example = ""
    @State private var pronunciation = ""
    @State private var isBookmarked = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // プレビューカード
                    FlashcardPreviewView(
                        word: word.isEmpty ? "単語" : word,
                        meaning: meaning.isEmpty ? "意味" : meaning,
                        category: category
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
                        .toggleStyle(SwitchToggleStyle(tint: Color(category.color)))
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("新しい単語")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addFlashcard()
                    }
                    .foregroundColor(Color(category.color))
                    .fontWeight(.semibold)
                    .disabled(!isValidInput)
                }
            }
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValidInput: Bool {
        !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addFlashcard() {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMeaning = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExample = example.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPronunciation = pronunciation.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedWord.isEmpty && !trimmedMeaning.isEmpty else {
            errorMessage = "単語と意味を入力してください。"
            showingError = true
            return
        }
        
        let flashcard = Flashcard(
            word: trimmedWord,
            meaning: trimmedMeaning,
            example: trimmedExample.isEmpty ? nil : trimmedExample,
            pronunciation: trimmedPronunciation.isEmpty ? nil : trimmedPronunciation,
            category: category
        )
        
        flashcard.isBookmarked = isBookmarked
        
        modelContext.insert(flashcard)
        category.flashcards.append(flashcard)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "フラッシュカードの追加に失敗しました: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct FlashcardPreviewView: View {
    let word: String
    let meaning: String
    let category: Category
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // カード背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(height: 200)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // 表面（単語）
            VStack(spacing: 12) {
                Text("単語")
                    .font(.caption)
                    .foregroundColor(Color(category.color))
                
                Text(word)
                    .font(.title.weight(.semibold))
                    .foregroundColor(Color("AsaDarkSlate"))
                    .multilineTextAlignment(.center)
            }
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            
            // 裏面（意味）
            VStack(spacing: 12) {
                Text("意味")
                    .font(.caption)
                    .foregroundColor(Color(category.color))
                
                Text(meaning)
                    .font(.title.weight(.semibold))
                    .foregroundColor(Color("AsaDarkSlate"))
                    .multilineTextAlignment(.center)
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : -180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.6)) {
                isFlipped.toggle()
            }
        }
        .padding(.horizontal)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("AsaSoftCream").opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("AsaDarkSlate").opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    let container = try! ModelContainer(for: Category.self, Flashcard.self, StudyProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let category = Category(name: "英語基礎", icon: "textbook", color: "AsaCoffeeBrown")
    container.mainContext.insert(category)
    
    return AddFlashcardView(category: category)
        .modelContainer(container)
}
