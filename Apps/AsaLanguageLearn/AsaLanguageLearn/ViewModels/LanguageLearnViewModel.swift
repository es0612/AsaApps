//
//  LanguageLearnViewModel.swift
//  AsaLanguageLearn
//
//  メインViewModel - アプリ全体の状態管理
//

import Foundation
import SwiftData

/// メインViewModel
@MainActor
@Observable
final class LanguageLearnViewModel {
    // MARK: - Properties

    /// 現在選択中のコース
    var selectedCourse: Course?

    /// 現在選択中のレッスン
    var selectedLesson: Lesson?

    /// ユーザープロファイル
    var userProfile: UserProfile?

    /// 全コース
    private(set) var courses: [Course] = []

    /// 今日復習すべきアイテム
    private(set) var itemsDueForReview: [LearningItem] = []

    /// ローディング状態
    private(set) var isLoading = false

    /// エラーメッセージ
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Computed Properties

    /// 今日の学習完了状態
    var hasStudiedToday: Bool {
        userProfile?.hasStudiedToday ?? false
    }

    /// 連続学習日数
    var currentStreak: Int {
        userProfile?.currentStreak ?? 0
    }

    /// 復習待ちアイテム数
    var dueItemsCount: Int {
        itemsDueForReview.count
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// 初期データをロード
    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            // ユーザープロファイルの取得または作成
            userProfile = try await fetchOrCreateUserProfile()

            // コースの取得
            courses = try await fetchCourses()

            // サンプルデータがなければ作成
            if courses.isEmpty {
                try await createSampleData()
                courses = try await fetchCourses()
            }

            // 復習対象アイテムの取得
            itemsDueForReview = try await fetchItemsDueForReview()

        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// コースを取得
    private func fetchCourses() async throws -> [Course] {
        let descriptor = FetchDescriptor<Course>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// ユーザープロファイルを取得または作成
    private func fetchOrCreateUserProfile() async throws -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(descriptor)

        if let existing = profiles.first {
            return existing
        }

        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        try modelContext.save()
        return newProfile
    }

    /// 復習対象アイテムを取得
    private func fetchItemsDueForReview() async throws -> [LearningItem] {
        let descriptor = FetchDescriptor<LearningItem>()
        let allItems = try modelContext.fetch(descriptor)

        return allItems.filter { item in
            guard let progress = item.progress else { return false }
            return progress.needsReview
        }
    }

    // MARK: - Sample Data

    /// サンプルデータを作成
    private func createSampleData() async throws {
        // 挨拶コース
        let greetingsCourse = Course(
            title: "基本の挨拶",
            subtitle: "英語での挨拶表現をマスターしよう",
            category: .greetings,
            difficulty: 1,
            estimatedMinutes: 15,
            sortOrder: 0
        )

        // レッスン1: 朝の挨拶
        let morningLesson = Lesson(
            title: "朝の挨拶",
            description: "Good morning などの朝の挨拶表現",
            sortOrder: 0
        )

        // 学習アイテム
        let items = [
            LearningItem(
                englishText: "Good morning",
                japaneseText: "おはようございます",
                pronunciation: "/ɡʊd ˈmɔːrnɪŋ/",
                exampleSentence: "Good morning! How are you today?",
                exampleTranslation: "おはようございます！今日の調子はいかがですか？",
                pronunciationTip: "「グッモーニン」と発音。morningの「r」は舌を丸めずに。",
                sortOrder: 0
            ),
            LearningItem(
                englishText: "Good morning, everyone",
                japaneseText: "皆さん、おはようございます",
                pronunciation: "/ɡʊd ˈmɔːrnɪŋ ˈevriwʌn/",
                exampleSentence: "Good morning, everyone. Let's get started.",
                exampleTranslation: "皆さん、おはようございます。始めましょう。",
                pronunciationTip: "everyoneの「ry」は「リ」ではなく「リィ」に近い音。",
                sortOrder: 1
            ),
            LearningItem(
                englishText: "Have a nice day",
                japaneseText: "良い一日を",
                pronunciation: "/hæv ə naɪs deɪ/",
                exampleSentence: "See you later. Have a nice day!",
                exampleTranslation: "また後で。良い一日を！",
                pronunciationTip: "Have aは「ハヴァ」とつなげて発音。",
                sortOrder: 2
            ),
        ]

        // 学習進捗を作成
        for item in items {
            let progress = LearningProgress()
            item.progress = progress
            morningLesson.items.append(item)
        }

        greetingsCourse.lessons.append(morningLesson)

        // レッスン2: 午後の挨拶
        let afternoonLesson = Lesson(
            title: "午後の挨拶",
            description: "Good afternoon などの午後の挨拶表現",
            sortOrder: 1
        )

        let afternoonItems = [
            LearningItem(
                englishText: "Good afternoon",
                japaneseText: "こんにちは（午後）",
                pronunciation: "/ɡʊd ˌæftərˈnuːn/",
                exampleSentence: "Good afternoon. How can I help you?",
                exampleTranslation: "こんにちは。何かお手伝いしましょうか？",
                pronunciationTip: "afternoonの強勢は後半の「noon」にある。",
                sortOrder: 0
            ),
            LearningItem(
                englishText: "Good evening",
                japaneseText: "こんばんは",
                pronunciation: "/ɡʊd ˈiːvnɪŋ/",
                exampleSentence: "Good evening, ladies and gentlemen.",
                exampleTranslation: "紳士淑女の皆様、こんばんは。",
                pronunciationTip: "eveningの「e」は長く伸ばす。",
                sortOrder: 1
            ),
        ]

        for item in afternoonItems {
            let progress = LearningProgress()
            item.progress = progress
            afternoonLesson.items.append(item)
        }

        greetingsCourse.lessons.append(afternoonLesson)

        modelContext.insert(greetingsCourse)

        // 旅行コース
        let travelCourse = Course(
            title: "旅行英会話",
            subtitle: "空港・ホテル・観光で使えるフレーズ",
            category: .travel,
            difficulty: 2,
            estimatedMinutes: 30,
            sortOrder: 1
        )

        let airportLesson = Lesson(
            title: "空港で使うフレーズ",
            description: "入国審査やチェックインで使う表現",
            sortOrder: 0
        )

        let airportItems = [
            LearningItem(
                englishText: "Where is the check-in counter?",
                japaneseText: "チェックインカウンターはどこですか？",
                pronunciation: "/weər ɪz ðə ˈtʃekɪn ˈkaʊntər/",
                exampleSentence: "Excuse me, where is the check-in counter for Japan Airlines?",
                exampleTranslation: "すみません、日本航空のチェックインカウンターはどこですか？",
                pronunciationTip: "Where isは「ウェアリズ」とつなげて発音。",
                sortOrder: 0
            ),
            LearningItem(
                englishText: "I'd like a window seat",
                japaneseText: "窓側の席がいいです",
                pronunciation: "/aɪd laɪk ə ˈwɪndoʊ siːt/",
                exampleSentence: "I'd like a window seat, please.",
                exampleTranslation: "窓側の席をお願いします。",
                pronunciationTip: "I'd likeは「アイドライク」と発音。",
                sortOrder: 1
            ),
        ]

        for item in airportItems {
            let progress = LearningProgress()
            item.progress = progress
            airportLesson.items.append(item)
        }

        travelCourse.lessons.append(airportLesson)

        modelContext.insert(travelCourse)

        // デモ用: 学習セッション履歴を作成（ダッシュボード表示用）
        let calendar = Calendar.current
        let sessionConfigs: [(daysAgo: Int, items: Int, correct: Int, duration: Int, score: Double)] = [
            (6, 5, 4, 480, 0.78),
            (5, 8, 6, 600, 0.82),
            (4, 0, 0, 0, 0),     // 休み
            (3, 10, 8, 720, 0.85),
            (2, 7, 6, 540, 0.88),
            (1, 12, 10, 900, 0.90),
            (0, 6, 5, 420, 0.83),
        ]

        for config in sessionConfigs where config.items > 0 {
            let session = StudySession(sessionType: .practice)
            let startOfDay = calendar.startOfDay(for: Date())
            let sessionDate = calendar.date(byAdding: .day, value: -config.daysAgo, to: startOfDay)!
            let sessionStart = calendar.date(byAdding: .hour, value: 6, to: sessionDate)!
            session.startedAt = sessionStart
            session.endedAt = sessionStart.addingTimeInterval(TimeInterval(config.duration))
            session.itemsPracticed = config.items
            session.correctCount = config.correct
            session.incorrectCount = config.items - config.correct
            session.averageScore = config.score
            modelContext.insert(session)
        }

        // デモ用: ユーザープロファイルに学習実績を反映
        if let profile = userProfile {
            profile.totalStudySeconds = 3660  // 約1時間
            profile.currentStreak = 3
            profile.bestStreak = 3
            profile.completedLessons = 4
            profile.masteredItems = 2
            profile.totalCorrect = 39
            profile.totalAnswers = 48
            profile.lastStudyDate = Date()
        }

        try modelContext.save()
    }

    // MARK: - Actions

    /// コースを選択
    func selectCourse(_ course: Course) {
        selectedCourse = course
        selectedLesson = nil
    }

    /// レッスンを選択
    func selectLesson(_ lesson: Lesson) {
        selectedLesson = lesson
    }

    /// 学習結果を記録
    func recordStudyResult(correct: Int, total: Int, durationSeconds: Int) {
        userProfile?.recordStudy(correct: correct, total: total, durationSeconds: durationSeconds)
        try? modelContext.save()
    }

    /// データを更新
    func refresh() async {
        await loadInitialData()
    }
}
