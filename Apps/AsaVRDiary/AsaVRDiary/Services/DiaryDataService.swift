//
//  DiaryDataService.swift
//  AsaVRDiary
//
//  Swift Data ラッパーサービス
//  日記エントリーの永続化を管理
//

import Foundation
import SwiftData

/// Swift Dataを使用した日記データ永続化サービス
@MainActor
final class DiaryDataService {
    // MARK: - Properties

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        do {
            let schema = Schema([DiaryEntry.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("SwiftDataの初期化に失敗しました: \(error)")
        }
    }

    // MARK: - CRUD Operations

    /// すべての日記エントリーを取得（日付降順）
    func fetchAllEntries() -> [DiaryEntry] {
        let descriptor = FetchDescriptor<DiaryEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("日記の取得に失敗: \(error)")
            return []
        }
    }

    /// 条件付きで日記エントリーを取得
    func fetchEntries(
        category: DiaryCategory? = nil,
        mood: DiaryMood? = nil,
        favoritesOnly: Bool = false,
        searchText: String? = nil
    ) -> [DiaryEntry] {
        var predicates: [Predicate<DiaryEntry>] = []

        // カテゴリフィルタ
        if let category = category {
            let categoryRaw = category.rawValue
            predicates.append(#Predicate<DiaryEntry> { entry in
                entry.categoryRawValue == categoryRaw
            })
        }

        // 気分フィルタ
        if let mood = mood {
            let moodRaw = mood.rawValue
            predicates.append(#Predicate<DiaryEntry> { entry in
                entry.moodRawValue == moodRaw
            })
        }

        // お気に入りフィルタ
        if favoritesOnly {
            predicates.append(#Predicate<DiaryEntry> { entry in
                entry.isFavorite == true
            })
        }

        // 検索フィルタ
        if let searchText = searchText, !searchText.isEmpty {
            predicates.append(#Predicate<DiaryEntry> { entry in
                entry.title.localizedStandardContains(searchText) ||
                entry.content.localizedStandardContains(searchText)
            })
        }

        // 複合Predicate作成
        let combinedPredicate: Predicate<DiaryEntry>?
        if predicates.isEmpty {
            combinedPredicate = nil
        } else if predicates.count == 1 {
            combinedPredicate = predicates[0]
        } else {
            // 複数条件の場合は最初の条件のみ使用（Swift Predicateの制限）
            combinedPredicate = predicates[0]
        }

        let descriptor = FetchDescriptor<DiaryEntry>(
            predicate: combinedPredicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            var results = try modelContext.fetch(descriptor)

            // 追加フィルタを手動適用（Predicateで結合できない場合）
            if let mood = mood, category != nil {
                results = results.filter { $0.mood == mood }
            }
            if favoritesOnly && (category != nil || mood != nil) {
                results = results.filter { $0.isFavorite }
            }
            if let searchText = searchText, !searchText.isEmpty, (category != nil || mood != nil || favoritesOnly) {
                results = results.filter {
                    $0.title.localizedCaseInsensitiveContains(searchText) ||
                    $0.content.localizedCaseInsensitiveContains(searchText)
                }
            }

            return results
        } catch {
            print("日記の取得に失敗: \(error)")
            return []
        }
    }

    /// 日付範囲で日記エントリーを取得
    func fetchEntries(from startDate: Date, to endDate: Date) -> [DiaryEntry] {
        let descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate<DiaryEntry> { entry in
                entry.date >= startDate && entry.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("日記の取得に失敗: \(error)")
            return []
        }
    }

    /// IDで日記エントリーを取得
    func fetchEntry(by id: UUID) -> DiaryEntry? {
        let descriptor = FetchDescriptor<DiaryEntry>(
            predicate: #Predicate<DiaryEntry> { entry in
                entry.id == id
            }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("日記の取得に失敗: \(error)")
            return nil
        }
    }

    /// 日記エントリーを保存
    func saveEntry(_ entry: DiaryEntry) {
        modelContext.insert(entry)

        do {
            try modelContext.save()
        } catch {
            print("日記の保存に失敗: \(error)")
        }
    }

    /// 日記エントリーを更新
    func updateEntry(_ entry: DiaryEntry) {
        entry.touch()

        do {
            try modelContext.save()
        } catch {
            print("日記の更新に失敗: \(error)")
        }
    }

    /// 日記エントリーを削除
    func deleteEntry(_ entry: DiaryEntry) {
        modelContext.delete(entry)

        do {
            try modelContext.save()
        } catch {
            print("日記の削除に失敗: \(error)")
        }
    }

    /// 変更を保存
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("変更の保存に失敗: \(error)")
        }
    }

    // MARK: - Statistics

    /// 統計データを計算
    func calculateStats() -> DiaryStats {
        let entries = fetchAllEntries()
        return DiaryStatsCalculator.calculate(from: entries)
    }

    // MARK: - Sample Data

    /// サンプルデータを作成（開発用）
    func createSampleData() {
        let calendar = Calendar.current
        let now = Date()

        let sampleEntries: [(String, String, DiaryCategory, DiaryMood, Int, Int)] = [
            ("朝活スタート", "今日から朝5時起きを始めた。まだ眠いけど、静かな時間は集中できる。", .daily, .calm, 3, 0),
            ("SwiftUI勉強", "RealityKitの基礎を学んだ。3Dは奥が深い。", .learning, .excited, 4, -1),
            ("家族でピクニック", "公園でお弁当。子供たちが楽しそうで嬉しかった。", .family, .veryHappy, 5, -2),
            ("プロジェクト完成", "AsaVRDiaryのMVP完成！VR空間で日記が見れるようになった。", .work, .happy, 4, -3),
            ("体調不良", "少し風邪気味。早めに寝よう。", .health, .tired, 2, -4),
            ("新しい趣味", "写真撮影を始めた。朝の光がきれい。", .hobby, .excited, 4, -5),
            ("感謝の日", "周りの人たちに支えられていることを実感した一日。", .special, .grateful, 5, -7),
            ("旅行計画", "夏休みの家族旅行を計画。沖縄に行きたい！", .travel, .happy, 4, -10),
            ("不安な夜", "明日のプレゼンが心配。準備は万全だけど…", .work, .anxious, 2, -14),
            ("普通の一日", "特に何もない平穏な日。それもまた良い。", .daily, .neutral, 3, -21),
        ]

        for (title, content, category, mood, intensity, daysAgo) in sampleEntries {
            guard let date = calendar.date(byAdding: .day, value: daysAgo, to: now) else { continue }

            let entry = DiaryEntry(
                title: title,
                content: content,
                date: date,
                category: category,
                mood: mood,
                moodIntensity: intensity
            )

            // 一部をお気に入りに
            if [DiaryMood.veryHappy, .grateful].contains(mood) {
                entry.isFavorite = true
            }

            modelContext.insert(entry)
        }

        do {
            try modelContext.save()
        } catch {
            print("サンプルデータの作成に失敗: \(error)")
        }
    }
}
