//
//  HistoryView.swift
//  AsaRecipeAI
//
//  認識履歴一覧
//

import SwiftUI

struct HistoryView: View {
    // MARK: - Properties

    var viewModel: RecipeAIViewModel

    @State private var showingClearAlert = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.recognitionHistory.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .background(Color("AsaSoftCream").opacity(0.3))
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !viewModel.recognitionHistory.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingClearAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color("AsaMocha"))
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshHistory()
            }
            .alert("履歴を削除", isPresented: $showingClearAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("すべて削除", role: .destructive) {
                    viewModel.clearAllHistory()
                }
            } message: {
                Text("すべての認識履歴を削除しますか？この操作は取り消せません。")
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(Color("AsaMutedSage"))

            Text("履歴がありません")
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            Text("食材を認識すると、ここに履歴が表示されます")
                .font(.subheadline)
                .foregroundStyle(Color("AsaMocha"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - History List View

    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.recognitionHistory) { history in
                    HistoryCard(history: history) {
                        viewModel.deleteHistory(history)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - History Card

struct HistoryCard: View {
    let history: RecognitionHistory
    let onDelete: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                // サムネイル
                if let thumbnailData = history.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("AsaMutedSage").opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Color("AsaMutedSage"))
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(history.recognizedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("AsaDarkSlate"))

                    HStack(spacing: 8) {
                        Label("\(history.ingredientCount)食材", systemImage: "leaf")
                        Label("\(history.generatedRecipeCount)レシピ", systemImage: "book")
                    }
                    .font(.caption)
                    .foregroundStyle(Color("AsaMutedSage"))
                }

                Spacer()

                // 展開/削除
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(Color("AsaMocha"))
                    }

                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color("AsaMutedSage"))
                    }
                }
            }

            // サマリー
            Text(history.summary)
                .font(.caption)
                .foregroundStyle(Color("AsaMocha"))

            // 展開時の詳細
            if isExpanded {
                Divider()

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(history.ingredients) { ingredient in
                        HStack(spacing: 4) {
                            Text(ingredient.emoji)
                                .font(.caption)
                            Text(ingredient.name)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("AsaSoftCream"))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    HistoryView(viewModel: RecipeAIViewModel(
        recipeAIService: RecipeAIService(),
        visionService: VisionService(),
        dataService: DataService(modelContext: try! ModelContainer(for: Recipe.self).mainContext)
    ))
}
