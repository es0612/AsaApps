import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var flashcards: [Flashcard]
    
    @AppStorage("studyRemindersEnabled") private var studyRemindersEnabled = true
    @AppStorage("dailyStudyGoal") private var dailyStudyGoal = 10
    @AppStorage("showPronunciation") private var showPronunciation = true
    @AppStorage("autoFlipCards") private var autoFlipCards = false
    @AppStorage("shuffleMode") private var shuffleMode = true
    
    @State private var showingDataExport = false
    @State private var showingDataImport = false
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // アプリ情報セクション
                Section {
                    AppInfoRow()
                }
                
                // 学習設定
                Section("学習設定") {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .frame(width: 24)
                        
                        Text("1日の目標")
                        
                        Spacer()
                        
                        Stepper(value: $dailyStudyGoal, in: 1...100) {
                            Text("\(dailyStudyGoal)枚")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                    
                    SettingsRow(
                        title: "発音を表示",
                        subtitle: "単語カードに発音記号を表示",
                        icon: "speaker.wave.2.fill",
                        color: "AsaMocha"
                    ) {
                        Toggle("", isOn: $showPronunciation)
                            .labelsHidden()
                    }
                    
                    SettingsRow(
                        title: "自動めくり",
                        subtitle: "一定時間後にカードを自動でめくる",
                        icon: "timer",
                        color: "AsaMutedSage"
                    ) {
                        Toggle("", isOn: $autoFlipCards)
                            .labelsHidden()
                    }
                    
                    SettingsRow(
                        title: "シャッフル再生",
                        subtitle: "学習時にカードをシャッフル",
                        icon: "shuffle",
                        color: "AsaDarkSlate"
                    ) {
                        Toggle("", isOn: $shuffleMode)
                            .labelsHidden()
                    }
                }
                
                // 通知設定
                Section("通知") {
                    SettingsRow(
                        title: "学習リマインダー",
                        subtitle: "毎日の学習を通知でお知らせ",
                        icon: "bell.fill",
                        color: "AsaCoffeeBrown"
                    ) {
                        Toggle("", isOn: $studyRemindersEnabled)
                            .labelsHidden()
                    }
                    
                    if studyRemindersEnabled {
                        NavigationLink(destination: NotificationSettingsView()) {
                            SettingsRow(
                                title: "通知時間の設定",
                                subtitle: "リマインダーの時間を変更",
                                icon: "clock.fill",
                                color: "AsaMocha"
                            )
                        }
                    }
                }
                
                // データ管理
                Section("データ管理") {
                    Button(action: { showingDataExport = true }) {
                        SettingsRow(
                            title: "データをエクスポート",
                            subtitle: "学習データをファイルに書き出し",
                            icon: "square.and.arrow.up.fill",
                            color: "AsaMutedSage"
                        )
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                    
                    // データインポート機能は一時的に無効化
                    // TODO: SwiftUI API互換性問題を修正後に再有効化
                    /*
                    Button(action: { showingDataImport = true }) {
                        SettingsRow(
                            title: "データをインポート",
                            subtitle: "ファイルから学習データを読み込み",
                            icon: "square.and.arrow.down.fill",
                            color: "AsaCoffeeBrown"
                        )
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                    */
                    
                    Button(action: { showingResetAlert = true }) {
                        SettingsRow(
                            title: "すべてのデータをリセット",
                            subtitle: "全ての学習データを削除",
                            icon: "trash.fill",
                            color: "AsaMocha"
                        )
                    }
                    .foregroundColor(.red)
                }
                
                // アプリ情報
                Section("アプリ情報") {
                    Button(action: { showingAbout = true }) {
                        SettingsRow(
                            title: "AsaFlashcardProについて",
                            subtitle: "バージョン情報とライセンス",
                            icon: "info.circle.fill",
                            color: "AsaDarkSlate"
                        )
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                    
                    Link(destination: URL(string: "https://github.com/es0612/AsaApps")!) {
                        SettingsRow(
                            title: "GitHub",
                            subtitle: "ソースコードを見る",
                            icon: "link",
                            color: "AsaCoffeeBrown"
                        )
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                    
                    Button(action: shareApp) {
                        SettingsRow(
                            title: "アプリをシェア",
                            subtitle: "友達にAsaFlashcardProを紹介",
                            icon: "square.and.arrow.up",
                            color: "AsaMutedSage"
                        )
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView(categories: categories, flashcards: flashcards)
        }
        .sheet(isPresented: $showingDataImport) {
            DataImportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("データをリセット", isPresented: $showingResetAlert) {
            Button("リセット", role: .destructive) {
                resetAllData()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("すべてのカテゴリ、フラッシュカード、学習データが削除されます。この操作は元に戻せません。")
        }
    }
    
    private func shareApp() {
        let items = ["AsaFlashcardProで楽しく単語学習！ https://github.com/es0612/AsaApps"]
        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
    
    private func resetAllData() {
        // すべてのフラッシュカードを削除
        for flashcard in flashcards {
            modelContext.delete(flashcard)
        }
        
        // すべてのカテゴリを削除
        for category in categories {
            modelContext.delete(category)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("データのリセットに失敗しました: \(error)")
        }
    }
}

struct AppInfoRow: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.largeTitle)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color("AsaCoffeeBrown").opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AsaFlashcardPro")
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("カテゴリ付き単語帳アプリ")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: String
    @ViewBuilder let content: () -> Content
    
    init(title: String, subtitle: String? = nil, icon: String, color: String, @ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.content = content
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(color))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                }
            }
            
            Spacer()
            
            content()
        }
        .padding(.vertical, 2)
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("notificationMinute") private var notificationMinute = 0
    
    var body: some View {
        List {
            Section("リマインダー時間") {
                HStack {
                    Text("時間")
                    Spacer()
                    Picker("時", selection: $notificationHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)時").tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 100, height: 100)
                }
                
                HStack {
                    Text("分")
                    Spacer()
                    Picker("分", selection: $notificationMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text("\(minute)分").tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 100, height: 100)
                }
            }
            
            Section {
                Text("毎日\(String(format: \"%02d:%02d\", notificationHour, notificationMinute))に学習のリマインダーが送信されます。")
                    .font(.caption)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
            }
        }
        .navigationTitle("通知設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [Category]
    let flashcards: [Flashcard]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("データエクスポート")
                    .font(.title.weight(.bold))
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("\(categories.count)個のカテゴリと\(flashcards.count)枚のフラッシュカードをエクスポートします。")
                    .font(.body)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: exportData) {
                    Text("エクスポート開始")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AsaCoffeeBrown"))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("データエクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
            }
        }
    }
    
    private func exportData() {
        let exportData = ExportData(
            exportDate: Date(),
            version: "1.0",
            categories: categories.map { category in
                ExportCategory(
                    id: category.id,
                    name: category.name,
                    icon: category.icon,
                    color: category.color,
                    createdAt: category.createdAt,
                    flashcards: category.flashcards.map { flashcard in
                        ExportFlashcard(
                            id: flashcard.id,
                            word: flashcard.word,
                            meaning: flashcard.meaning,
                            example: flashcard.example,
                            pronunciation: flashcard.pronunciation,
                            isBookmarked: flashcard.isBookmarked,
                            createdAt: flashcard.createdAt,
                            studyProgress: ExportStudyProgress(
                                correctAnswers: flashcard.studyProgress.correctAnswers,
                                totalAnswers: flashcard.studyProgress.totalAnswers,
                                lastStudiedAt: flashcard.studyProgress.lastStudiedAt,
                                streak: flashcard.studyProgress.streak,
                                isStudied: flashcard.studyProgress.isStudied,
                                nextReviewDate: flashcard.studyProgress.nextReviewDate
                            )
                        )
                    }
                )
            }
        )
        
        do {
            let jsonData = try JSONEncoder().encode(exportData)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent("AsaFlashcardPro_Export_\(DateFormatter.fileNameFormatter.string(from: Date())).json")
            
            try jsonData.write(to: fileURL)
            
            // ファイル共有
            let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityController, animated: true)
            }
            
            dismiss()
        } catch {
            print("エクスポートエラー: \(error)")
            // エラーハンドリングは後で改善
        }
    }
}

struct DataImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingFilePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color("AsaMutedSage"))
                
                Text("データインポート")
                    .font(.title.weight(.bold))
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("エクスポートしたデータファイルから学習データを読み込みます。")
                    .font(.body)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: importData) {
                    Text("ファイルを選択")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AsaMutedSage"))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("データインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
            }
        }
        // ファイルインポート機能は一時的に無効化
        // TODO: SwiftUI API互換性問題を修正後に再有効化
        /*
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false,
            onCompletion: processImportFile
        )
        */
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func importData() {
        showingFilePicker = true
    }
    
    private func processImportFile(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "ファイルへのアクセス権限がありません。"
                showingError = true
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let jsonData = try Data(contentsOf: url)
                let exportData = try JSONDecoder().decode(ExportData.self, from: jsonData)
                
                // データをSwiftDataに保存
                for exportCategory in exportData.categories {
                    let category = Category(
                        name: exportCategory.name,
                        icon: exportCategory.icon,
                        color: exportCategory.color
                    )
                    category.id = exportCategory.id
                    category.createdAt = exportCategory.createdAt
                    
                    modelContext.insert(category)
                    
                    for exportFlashcard in exportCategory.flashcards {
                        let flashcard = Flashcard(
                            word: exportFlashcard.word,
                            meaning: exportFlashcard.meaning,
                            example: exportFlashcard.example,
                            pronunciation: exportFlashcard.pronunciation,
                            category: category
                        )
                        flashcard.id = exportFlashcard.id
                        flashcard.isBookmarked = exportFlashcard.isBookmarked
                        flashcard.createdAt = exportFlashcard.createdAt
                        
                        // 学習進捗データを復元
                        flashcard.studyProgress.correctAnswers = exportFlashcard.studyProgress.correctAnswers
                        flashcard.studyProgress.totalAnswers = exportFlashcard.studyProgress.totalAnswers
                        flashcard.studyProgress.lastStudiedAt = exportFlashcard.studyProgress.lastStudiedAt
                        flashcard.studyProgress.streak = exportFlashcard.studyProgress.streak
                        flashcard.studyProgress.isStudied = exportFlashcard.studyProgress.isStudied
                        flashcard.studyProgress.nextReviewDate = exportFlashcard.studyProgress.nextReviewDate
                        
                        modelContext.insert(flashcard)
                        category.flashcards.append(flashcard)
                    }
                }
                
                try modelContext.save()
                dismiss()
                
            } catch {
                errorMessage = "ファイルの読み込みに失敗しました: \(error.localizedDescription)"
                showingError = true
            }
            
        case .failure(let error):
            errorMessage = "ファイル選択エラー: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // アプリアイコンとタイトル
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 100))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text("AsaFlashcardPro")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("Version 1.0.0")
                            .font(.title3)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    // 説明
                    VStack(spacing: 16) {
                        Text("AsaAppsプロジェクトの一部として開発されたフラッシュカード学習アプリです。")
                            .font(.body)
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("カテゴリ別の単語整理、進捗追跡、間隔反復学習アルゴリズムにより、効率的な記憶学習をサポートします。")
                            .font(.body)
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // 開発者情報
                    VStack(spacing: 12) {
                        Text("開発者")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("朝活パパエンジニア")
                            .font(.body)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text("SwiftUI学習の一環として開発")
                            .font(.caption)
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                    }
                    
                    // ライセンス
                    VStack(spacing: 12) {
                        Text("ライセンス")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text("MIT License")
                            .font(.body)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("オープンソースソフトウェアとして公開されています")
                            .font(.caption)
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                    }
                }
                .padding()
            }
            .navigationTitle("アプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaDarkSlate"))
                }
            }
        }
    }
}

// MARK: - Export Data Structures
struct ExportData: Codable {
    let exportDate: Date
    let version: String
    let categories: [ExportCategory]
}

struct ExportCategory: Codable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let createdAt: Date
    let flashcards: [ExportFlashcard]
}

struct ExportFlashcard: Codable {
    let id: UUID
    let word: String
    let meaning: String
    let example: String?
    let pronunciation: String?
    let isBookmarked: Bool
    let createdAt: Date
    let studyProgress: ExportStudyProgress
}

struct ExportStudyProgress: Codable {
    let correctAnswers: Int
    let totalAnswers: Int
    let lastStudiedAt: Date?
    let streak: Int
    let isStudied: Bool
    let nextReviewDate: Date?
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

#Preview {
    SettingsView()
        .modelContainer(for: [Category.self, Flashcard.self, StudyProgress.self], inMemory: true)
}
