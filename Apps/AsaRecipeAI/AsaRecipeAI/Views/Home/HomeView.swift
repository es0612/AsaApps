//
//  HomeView.swift
//  AsaRecipeAI
//
//  ホーム画面 - メインの食材認識・レシピ提案フロー
//

import SwiftUI
import SwiftData
import PhotosUI
import AsaUIKit

struct HomeView: View {
    // MARK: - Properties

    var viewModel: RecipeAIViewModel

    @State private var selectedPhotosItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var navigateToAnalysis = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerSection

                    // AI状態表示
                    aiStatusSection

                    // 画像選択セクション
                    imageSelectionSection

                    // 選択された画像
                    if let image = viewModel.selectedImage {
                        selectedImageSection(image)
                    }

                    // 認識結果
                    if !viewModel.recognizedIngredients.isEmpty {
                        recognizedIngredientsSection
                    }

                    // レシピ生成ボタン
                    if viewModel.appState.canGenerateRecipes {
                        generateRecipesButton
                    }

                    // 生成されたレシピ
                    if !viewModel.completedRecipes.isEmpty {
                        generatedRecipesSection
                    }

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color("AsaSoftCream").opacity(0.3))
            .navigationTitle("AsaRecipeAI")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: selectedPhotosItem) { _, newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
            .alert("エラー", isPresented: .init(
                get: { viewModel.showError },
                set: { viewModel.showError = $0 }
            )) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "frying.pan.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("AsaCoffeeBrown"))

            Text("食材を撮影してレシピを発見")
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            Text("Foundation Models + Vision でオンデバイスAI")
                .font(.caption)
                .foregroundStyle(Color("AsaMutedSage"))
        }
        .padding(.vertical)
    }

    // MARK: - AI Status Section

    private var aiStatusSection: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(viewModel.aiStatusText)
                .font(.caption)
                .foregroundStyle(Color("AsaDarkSlate"))

            if viewModel.isDemoMode {
                Text("・サンプルで動作中")
                    .font(.caption2)
                    .foregroundStyle(Color("AsaMocha"))
            }

            Spacer()

            Text(viewModel.appState.description)
                .font(.caption)
                .foregroundStyle(Color("AsaMocha"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// AI ステータスドットの色（デモモード=オレンジ／ライブ=緑／準備中=グレー）
    private var statusColor: Color {
        if viewModel.isDemoMode { return .orange }
        return viewModel.isAIReady ? .green : .gray
    }

    // MARK: - Image Selection Section

    private var imageSelectionSection: some View {
        VStack(spacing: 16) {
            Text("写真を選択")
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            HStack(spacing: 16) {
                // PhotosPickerボタン
                PhotosPicker(
                    selection: $selectedPhotosItem,
                    matching: .images
                ) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 32))
                        Text("写真を選択")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color("AsaCoffeeBrown").opacity(0.1))
                    .foregroundStyle(Color("AsaCoffeeBrown"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // カメラボタン（将来の拡張用）
                Button {
                    // カメラ機能は将来実装
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 32))
                        Text("撮影する")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color("AsaMutedSage").opacity(0.2))
                    .foregroundStyle(Color("AsaMutedSage"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(true)
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Selected Image Section

    private func selectedImageSection(_ image: UIImage) -> some View {
        VStack(spacing: 12) {
            Text("選択した画像")
                .font(.headline)
                .foregroundStyle(Color("AsaDarkSlate"))

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)

            HStack(spacing: 12) {
                // 分析ボタン
                AsaButton(
                    title: viewModel.isAnalyzing ? "分析中..." : "食材を認識",
                    action: {
                        Task {
                            await viewModel.analyzeSelectedImage()
                        }
                    },
                    isEnabled: !viewModel.isAnalyzing && viewModel.isAIReady
                )

                // クリアボタン
                Button {
                    viewModel.clearImage()
                    selectedPhotosItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color("AsaMocha"))
                }
            }

            if viewModel.isAnalyzing {
                ProgressView()
                    .tint(Color("AsaCoffeeBrown"))
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recognized Ingredients Section

    private var recognizedIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("認識された食材")
                    .font(.headline)
                    .foregroundStyle(Color("AsaDarkSlate"))

                Spacer()

                Text("\(viewModel.recognizedIngredients.count)種類")
                    .font(.caption)
                    .foregroundStyle(Color("AsaMocha"))
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.recognizedIngredients) { ingredient in
                    IngredientCard(ingredient: ingredient)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Generate Recipes Button

    private var generateRecipesButton: some View {
        VStack(spacing: 8) {
            AsaButton(
                title: viewModel.isGeneratingRecipes ? "生成中..." : "🍳 レシピを提案",
                action: {
                    Task {
                        await viewModel.generateRecipes()
                    }
                },
                isEnabled: !viewModel.isGeneratingRecipes && viewModel.isAIReady
            )

            if viewModel.isGeneratingRecipes {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Color("AsaCoffeeBrown"))
                    Text("AIがレシピを考えています...")
                        .font(.caption)
                        .foregroundStyle(Color("AsaMocha"))
                }
            }
        }
    }

    // MARK: - Generated Recipes Section

    private var generatedRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("おすすめレシピ")
                    .font(.headline)
                    .foregroundStyle(Color("AsaDarkSlate"))

                Spacer()

                Text("\(viewModel.completedRecipes.count)件")
                    .font(.caption)
                    .foregroundStyle(Color("AsaMocha"))
            }

            ForEach(viewModel.completedRecipes) { recipe in
                RecipeCard(
                    recipe: recipe,
                    onFavorite: {
                        viewModel.addToFavorites(recipe)
                    }
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Private Methods

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                viewModel.selectImage(uiImage)
            } else {
                viewModel.reportImageLoadError("画像のデコードに失敗しました")
            }
        } catch {
            // 空 UIImage を渡すと Vision がクラッシュする可能性があるため、エラー報告に変更
            viewModel.reportImageLoadError()
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView(viewModel: RecipeAIViewModel(
        recipeAIService: RecipeAIService(),
        visionService: VisionService(),
        dataService: DataService(modelContext: try! ModelContainer(for: Recipe.self).mainContext)
    ))
}
