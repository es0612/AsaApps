//
//  SettingsView.swift
//  AsaRecipeAI
//
//  設定画面 - ユーザー設定の管理
//

import SwiftUI
import SwiftData
import AsaUIKit

struct SettingsView: View {
    // MARK: - Properties

    var viewModel: RecipeAIViewModel

    @State private var maxCookingTime: Double = 60
    @State private var defaultServings: Int = 2
    @State private var recipeCount: Int = 3
    @State private var autoSaveHistory: Bool = true
    @State private var selectedRestriction: DietaryRestriction = .none
    @State private var hasChanges = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // AI設定
                aiSettingsSection

                // レシピ設定
                recipeSettingsSection

                // 食事制限
                dietarySection

                // 履歴設定
                historySection

                // 統計情報
                if let stats = viewModel.statistics {
                    statisticsSection(stats)
                }

                // アプリ情報
                appInfoSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadPreferences()
            }
            .onChange(of: maxCookingTime) { _, _ in hasChanges = true }
            .onChange(of: defaultServings) { _, _ in hasChanges = true }
            .onChange(of: recipeCount) { _, _ in hasChanges = true }
            .onChange(of: autoSaveHistory) { _, _ in hasChanges = true }
            .onChange(of: selectedRestriction) { _, _ in hasChanges = true }
            .toolbar {
                if hasChanges {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("保存") {
                            savePreferences()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - AI Settings Section

    private var aiSettingsSection: some View {
        Section {
            HStack {
                Label("AI状態", systemImage: "brain")
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isAIReady ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isAIReady ? "準備完了" : "準備中...")
                        .font(.subheadline)
                        .foregroundStyle(Color("AsaMutedSage"))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Label("対応デバイス", systemImage: "iphone")
                Text("iPhone 15 Pro / iPhone 16シリーズ以降")
                    .font(.caption)
                    .foregroundStyle(Color("AsaMutedSage"))
            }
        } header: {
            Text("Foundation Models")
        } footer: {
            Text("オンデバイスAIを使用してレシピを生成します。インターネット接続は不要です。")
        }
    }

    // MARK: - Recipe Settings Section

    private var recipeSettingsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("最大調理時間", systemImage: "clock")
                    Spacer()
                    Text("\(Int(maxCookingTime))分")
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                }

                Slider(value: $maxCookingTime, in: 10...180, step: 5)
                    .tint(Color("AsaCoffeeBrown"))
            }

            Stepper(value: $defaultServings, in: 1...8) {
                HStack {
                    Label("デフォルト人数", systemImage: "person.2")
                    Spacer()
                    Text("\(defaultServings)人分")
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                }
            }

            Stepper(value: $recipeCount, in: 1...5) {
                HStack {
                    Label("生成レシピ数", systemImage: "book")
                    Spacer()
                    Text("\(recipeCount)件")
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                }
            }
        } header: {
            Text("レシピ生成")
        }
    }

    // MARK: - Dietary Section

    private var dietarySection: some View {
        Section {
            Picker(selection: $selectedRestriction) {
                ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                    HStack {
                        Text(restriction.icon)
                        Text(restriction.rawValue)
                    }
                    .tag(restriction)
                }
            } label: {
                Label("食事制限", systemImage: "leaf")
            }

            if selectedRestriction != .none {
                Text(selectedRestriction.description)
                    .font(.caption)
                    .foregroundStyle(Color("AsaMutedSage"))
            }
        } header: {
            Text("食事制限")
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        Section {
            Toggle(isOn: $autoSaveHistory) {
                Label("自動保存", systemImage: "clock.arrow.circlepath")
            }
            .tint(Color("AsaCoffeeBrown"))
        } header: {
            Text("履歴")
        } footer: {
            Text("食材認識結果を自動的に履歴に保存します。")
        }
    }

    // MARK: - Statistics Section

    private func statisticsSection(_ stats: AppStatistics) -> some View {
        Section {
            HStack {
                Label("保存レシピ", systemImage: "book.closed")
                Spacer()
                Text("\(stats.totalRecipes)件")
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            HStack {
                Label("お気に入り", systemImage: "heart.fill")
                Spacer()
                Text("\(stats.favoriteRecipes)件")
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            HStack {
                Label("認識回数", systemImage: "camera")
                Spacer()
                Text("\(stats.totalRecognitions)回")
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            HStack {
                Label("認識食材", systemImage: "leaf")
                Spacer()
                Text("\(stats.totalIngredientsRecognized)種類")
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            HStack {
                Label("調理回数", systemImage: "flame.fill")
                Spacer()
                Text("\(stats.totalCookCount)回")
                    .foregroundStyle(Color("AsaMutedSage"))
            }
        } header: {
            Text("統計")
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section {
            HStack {
                Label("アプリ名", systemImage: "info.circle")
                Spacer()
                Text("AsaRecipeAI")
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            HStack {
                Label("バージョン", systemImage: "number")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            HStack {
                Label("アプリ番号", systemImage: "number.circle")
                Spacer()
                Text("#88")
                    .foregroundStyle(Color("AsaMutedSage"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Label("技術スタック", systemImage: "cpu")
                Text("Foundation Models + Vision + SwiftUI + Swift Data")
                    .font(.caption)
                    .foregroundStyle(Color("AsaMutedSage"))
            }
        } header: {
            Text("アプリ情報")
        } footer: {
            Text("AsaApps 100アプリチャレンジ")
        }
    }

    // MARK: - Private Methods

    private func loadPreferences() {
        guard let preferences = viewModel.userPreferences else { return }
        maxCookingTime = Double(preferences.maxCookingTime)
        defaultServings = preferences.defaultServings
        recipeCount = preferences.recipeCount
        autoSaveHistory = preferences.autoSaveHistory
        selectedRestriction = preferences.dietaryRestriction ?? .none
        hasChanges = false
    }

    private func savePreferences() {
        guard let preferences = viewModel.userPreferences else { return }
        preferences.maxCookingTime = Int(maxCookingTime)
        preferences.defaultServings = defaultServings
        preferences.recipeCount = recipeCount
        preferences.autoSaveHistory = autoSaveHistory
        preferences.dietaryRestriction = selectedRestriction

        viewModel.updatePreferences(preferences)
        hasChanges = false
    }
}

// MARK: - Preview

#Preview {
    SettingsView(viewModel: RecipeAIViewModel(
        recipeAIService: RecipeAIService(),
        visionService: VisionService(),
        dataService: DataService(modelContext: try! ModelContainer(for: Recipe.self).mainContext)
    ))
}
