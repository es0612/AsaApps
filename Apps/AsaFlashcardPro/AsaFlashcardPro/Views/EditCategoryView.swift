import SwiftUI
import SwiftData

struct EditCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    
    @State private var categoryName = ""
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "AsaCoffeeBrown"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let availableIcons = [
        "folder", "textbook", "character.book.closed", "laptopcomputer", "brain",
        "heart", "star", "flag", "bookmark", "tag", "globe", "person", "house",
        "car", "airplane", "camera", "music.note", "gamecontroller", "sportscourt",
        "leaf", "pawprint", "flame", "snowflake", "sun.max", "moon"
    ]
    
    private let availableColors = [
        "AsaCoffeeBrown", "AsaMocha", "AsaSoftCream", "AsaDarkSlate", "AsaMutedSage"
    ]
    
    private let colorNames = [
        "AsaCoffeeBrown": "コーヒーブラウン",
        "AsaMocha": "モカ",
        "AsaSoftCream": "ソフトクリーム",
        "AsaDarkSlate": "ダークスレート",
        "AsaMutedSage": "ミュートセージ"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // プレビューカード
                    PreviewCard(name: categoryName.isEmpty ? "カテゴリ名" : categoryName, 
                               icon: selectedIcon, 
                               color: selectedColor)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // カテゴリ名入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("カテゴリ名")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            TextField("例: 英語基礎", text: $categoryName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // アイコン選択
                        VStack(alignment: .leading, spacing: 8) {
                            Text("アイコン")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    IconSelectionView(
                                        icon: icon,
                                        isSelected: selectedIcon == icon,
                                        color: selectedColor
                                    ) {
                                        selectedIcon = icon
                                    }
                                }
                            }
                        }
                        
                        // カラー選択
                        VStack(alignment: .leading, spacing: 8) {
                            Text("テーマカラー")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            VStack(spacing: 8) {
                                ForEach(availableColors, id: \.self) { color in
                                    ColorSelectionView(
                                        color: color,
                                        colorName: colorNames[color] ?? color,
                                        isSelected: selectedColor == color
                                    ) {
                                        selectedColor = color
                                    }
                                }
                            }
                        }
                        
                        // カテゴリ統計情報
                        CategoryInfoView(category: category)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("カテゴリを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .foregroundColor(Color(selectedColor))
                    .fontWeight(.semibold)
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            loadCategoryData()
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadCategoryData() {
        categoryName = category.name
        selectedIcon = category.icon
        selectedColor = category.color
    }
    
    private func saveChanges() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "カテゴリ名を入力してください。"
            showingError = true
            return
        }
        
        category.name = trimmedName
        category.icon = selectedIcon
        category.color = selectedColor
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "カテゴリの更新に失敗しました: \\(error.localizedDescription)"
            showingError = true
        }
    }
}

struct CategoryInfoView: View {
    let category: Category
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ情報")
                .font(.headline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            VStack(spacing: 8) {
                HStack {
                    Text("作成日:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text(category.createdAt, style: .date)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                
                HStack {
                    Text("総単語数:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text("\\(category.totalFlashcards)枚")
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                
                HStack {
                    Text("学習済み:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text("\\(category.studiedFlashcards)枚")
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                
                HStack {
                    Text("進捗率:")
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    Spacer()
                    Text("\\(Int(category.studyProgress * 100))%")
                        .fontWeight(.medium)
                        .foregroundColor(Color(category.color))
                }
            }
            .font(.subheadline)
            
            if category.totalFlashcards > 0 {
                ProgressView(value: category.studyProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(category.color)))
                    .scaleEffect(y: 1.5)
            }
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
    container.mainContext.insert(category)
    
    return EditCategoryView(category: category)
        .modelContainer(container)
}