import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
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
                    PreviewCard(name: categoryName.isEmpty ? "新しいカテゴリ" : categoryName, 
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
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("新しいカテゴリ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createCategory()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .fontWeight(.semibold)
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "カテゴリ名を入力してください。"
            showingError = true
            return
        }
        
        let category = Category(name: trimmedName, icon: selectedIcon, color: selectedColor)
        modelContext.insert(category)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "カテゴリの作成に失敗しました: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct PreviewCard: View {
    let name: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color(color))
            
            Text(name)
                .font(.title2.weight(.semibold))
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("0枚の単語")
                .font(.subheadline)
                .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color("AsaSoftCream").opacity(0.3))
        )
        .padding(.horizontal)
    }
}

struct IconSelectionView: View {
    let icon: String
    let isSelected: Bool
    let color: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? Color(color) : Color("AsaDarkSlate").opacity(0.6))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color(color).opacity(0.1) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(color) : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ColorSelectionView: View {
    let color: String
    let colorName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(color))
                    .frame(width: 24, height: 24)
                
                Text(colorName)
                    .font(.body)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(color))
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(color).opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(color) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddCategoryView()
        .modelContainer(for: [Category.self, Flashcard.self, StudyProgress.self], inMemory: true)
}