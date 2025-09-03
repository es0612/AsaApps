import SwiftUI
import WidgetKit

struct SettingsView: View {
    @State private var selectedCategory: QuoteCategory = .encouragement
    @State private var updateFrequency: SharedDefaults.UpdateFrequency = .oneHour
    @State private var isRandomMode: Bool = false
    @State private var showingResetAlert = false
    @State private var showingAboutSheet = false
    
    private let sharedDefaults = SharedDefaults.shared
    
    var body: some View {
        NavigationView {
            Form {
                // ウィジェット設定セクション
                widgetSettingsSection
                
                // 更新設定セクション
                updateSettingsSection
                
                // 統計セクション
                statisticsSection
                
                // その他セクション
                otherSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSettings()
            }
            .onChange(of: selectedCategory) { category in
                sharedDefaults.selectedCategory = category
                updateWidget()
            }
            .onChange(of: updateFrequency) { frequency in
                sharedDefaults.updateFrequency = frequency
                updateWidget()
            }
            .onChange(of: isRandomMode) { randomMode in
                sharedDefaults.isRandomMode = randomMode
                updateWidget()
            }
            .alert("設定をリセット", isPresented: $showingResetAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    resetSettings()
                }
            } message: {
                Text("すべての設定を初期値に戻します。お気に入りも削除されます。")
            }
            .sheet(isPresented: $showingAboutSheet) {
                AboutView()
            }
        }
    }
    
    // MARK: - Widget Settings Section
    private var widgetSettingsSection: some View {
        Section(header: Text("ウィジェット設定")) {
            // カテゴリ選択
            Picker("表示カテゴリ", selection: $selectedCategory) {
                ForEach(QuoteCategory.allCases, id: \.self) { category in
                    HStack {
                        Text(category.emoji)
                        Text(category.displayName)
                    }
                    .tag(category)
                }
            }
            .disabled(isRandomMode)
            
            // ランダムモード
            Toggle("ランダム表示", isOn: $isRandomMode)
            
            if isRandomMode {
                Text("全カテゴリからランダムに名言を表示します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Update Settings Section
    private var updateSettingsSection: some View {
        Section(header: Text("更新設定")) {
            Picker("更新頻度", selection: $updateFrequency) {
                ForEach(SharedDefaults.UpdateFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            
            if let lastUpdate = sharedDefaults.lastUpdateTime {
                HStack {
                    Text("最終更新")
                    Spacer()
                    Text(lastUpdate.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
            }
            
            Button("今すぐ更新") {
                forceUpdate()
            }
            .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        Section(header: Text("統計")) {
            HStack {
                Text("お気に入り数")
                Spacer()
                Text("\(sharedDefaults.favoriteQuotes.count)件")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("総名言数")
                Spacer()
                Text("\(QuoteDataProvider.shared.getAllQuotes().count)件")
                    .foregroundColor(.secondary)
            }
            
            if let currentQuote = sharedDefaults.lastDisplayedQuote {
                VStack(alignment: .leading, spacing: 4) {
                    Text("現在のウィジェット表示")
                    Text("\"\(currentQuote.text)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    Text("— \(currentQuote.author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Other Section
    private var otherSection: some View {
        Section(header: Text("その他")) {
            Button("このアプリについて") {
                showingAboutSheet = true
            }
            .foregroundColor(Color("AsaCoffeeBrown"))
            
            Button("設定をリセット") {
                showingResetAlert = true
            }
            .foregroundColor(.red)
        }
    }
    
    // MARK: - Methods
    private func loadSettings() {
        selectedCategory = sharedDefaults.selectedCategory
        updateFrequency = sharedDefaults.updateFrequency
        isRandomMode = sharedDefaults.isRandomMode
    }
    
    private func updateWidget() {
        WidgetCenter.shared.reloadAllTimelines()
        
        // フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func forceUpdate() {
        sharedDefaults.markAsUpdated()
        let newQuote = sharedDefaults.getQuoteForWidget()
        sharedDefaults.lastDisplayedQuote = newQuote
        updateWidget()
    }
    
    private func resetSettings() {
        sharedDefaults.resetToDefaults()
        loadSettings()
        updateWidget()
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // アプリアイコン
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    // アプリ情報
                    VStack(spacing: 8) {
                        Text("AsaQuoteWidget")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("名言ウィジェット")
                            .font(.title2)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("バージョン 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 説明
                    VStack(alignment: .leading, spacing: 16) {
                        Text("このアプリについて")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("AsaQuoteWidgetは、朝活パパエンジニアのためのモチベーション名言アプリです。ホーム画面のウィジェットに励ましの名言を表示し、毎日の活力をお届けします。")
                            .font(.body)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .lineSpacing(4)
                        
                        Text("特徴")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "widget.small", text: "ホーム画面ウィジェット対応")
                            FeatureRow(icon: "heart.fill", text: "お気に入り名言の保存")
                            FeatureRow(icon: "tag.fill", text: "カテゴリ別名言分類")
                            FeatureRow(icon: "clock.fill", text: "自動更新機能")
                            FeatureRow(icon: "square.and.arrow.up", text: "名言の共有機能")
                        }
                    }
                    .padding(.horizontal)
                    
                    // フッター
                    Text("AsaApps プロジェクト")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("このアプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}