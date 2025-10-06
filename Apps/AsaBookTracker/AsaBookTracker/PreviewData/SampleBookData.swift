// AsaApps/Apps/AsaBookTracker/PreviewData/SampleBookData.swift
import Foundation
import SwiftData

/// プレビューとデバッグ用のサンプルデータを提供するヘルパークラス
struct SampleBookData {

    /// サンプル本データを生成してModelContextに登録
    /// - Parameter context: SwiftDataのModelContext
    static func loadSampleData(into context: ModelContext) {
        // 既存のデータをクリア（デバッグ用）
        clearAllData(from: context)

        // サンプル本データを作成
        let sampleBooks = createSampleBooks()

        // 各本をModelContextに登録
        for bookData in sampleBooks {
            let book = bookData.book
            let progress = bookData.progress

            // 本と進捗を登録
            context.insert(book)
            context.insert(progress)
            book.progress = progress

            // 読書セッションを登録（ある場合）
            for session in bookData.sessions {
                context.insert(session)
                session.book = book
                book.sessions.append(session)
            }
        }

        // 保存
        do {
            try context.save()
            print("✅ サンプルデータを正常に登録しました（\(sampleBooks.count)冊）")
        } catch {
            print("❌ サンプルデータの登録に失敗: \(error)")
        }
    }

    /// 全データをクリア（デバッグ用）
    private static func clearAllData(from context: ModelContext) {
        do {
            // 既存の本を全削除（カスケード削除で関連データも削除される）
            try context.delete(model: Book.self)
            try context.save()
            print("🗑️ 既存データをクリアしました")
        } catch {
            print("⚠️ データクリアに失敗: \(error)")
        }
    }

    /// サンプル本データを生成
    private static func createSampleBooks() -> [(book: Book, progress: ReadingProgress, sessions: [ReadingSession])] {
        var booksData: [(book: Book, progress: ReadingProgress, sessions: [ReadingSession])] = []

        // 1. リーダブルコード（技術書/完読/評価5）
        let book1 = Book(
            title: "リーダブルコード",
            author: "Dustin Boswell, Trevor Foucher",
            totalPages: 260,
            genre: BookGenre.technical.rawValue,
            isbn: "9784873115658"
        )
        book1.summary = "より良いコードを書くためのシンプルで実践的なテクニック集"

        let progress1 = ReadingProgress(currentPage: 260, status: .completed)
        progress1.startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        progress1.completedDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        progress1.rating = 5
        progress1.review = "プログラミングの本質を理解できる素晴らしい本。コードの可読性を高める具体的なテクニックが満載。"

        let sessions1 = createCompletedBookSessions(book: book1, startDate: progress1.startDate!, endDate: progress1.completedDate!, totalPages: 260)

        booksData.append((book1, progress1, sessions1))

        // 2. 人を動かす（ビジネス/完読/評価4）
        let book2 = Book(
            title: "人を動かす",
            author: "デール・カーネギー",
            totalPages: 320,
            genre: BookGenre.business.rawValue,
            isbn: "9784422100500"
        )
        book2.summary = "人間関係の古典的名著。コミュニケーションと影響力の原則を学ぶ"

        let progress2 = ReadingProgress(currentPage: 320, status: .completed)
        progress2.startDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())
        progress2.completedDate = Calendar.current.date(byAdding: .day, value: -40, to: Date())
        progress2.rating = 4
        progress2.review = "時代を超えて役立つ人間関係の原則。実践的で分かりやすい。"

        let sessions2 = createCompletedBookSessions(book: book2, startDate: progress2.startDate!, endDate: progress2.completedDate!, totalPages: 320)

        booksData.append((book2, progress2, sessions2))

        // 3. ハリー・ポッターと賢者の石（小説/完読/評価5）
        let book3 = Book(
            title: "ハリー・ポッターと賢者の石",
            author: "J.K.ローリング",
            totalPages: 464,
            genre: BookGenre.fiction.rawValue,
            isbn: "9784915512377"
        )
        book3.summary = "魔法の世界へようこそ。少年の成長と冒険の物語"

        let progress3 = ReadingProgress(currentPage: 464, status: .completed)
        progress3.startDate = Calendar.current.date(byAdding: .day, value: -90, to: Date())
        progress3.completedDate = Calendar.current.date(byAdding: .day, value: -80, to: Date())
        progress3.rating = 5
        progress3.review = "何度読んでも面白い！魔法の世界に引き込まれる素晴らしいストーリー。"

        let sessions3 = createCompletedBookSessions(book: book3, startDate: progress3.startDate!, endDate: progress3.completedDate!, totalPages: 464)

        booksData.append((book3, progress3, sessions3))

        // 4. 1984年（小説/読書中/進捗65%）
        let book4 = Book(
            title: "1984年",
            author: "ジョージ・オーウェル",
            totalPages: 400,
            genre: BookGenre.fiction.rawValue,
            isbn: "9784151200014"
        )
        book4.summary = "全体主義社会を描いたディストピア小説の傑作"

        let progress4 = ReadingProgress(currentPage: 260, status: .reading)
        progress4.startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())

        let sessions4 = createOngoingBookSessions(book: book4, startDate: progress4.startDate!, currentPage: 260)

        booksData.append((book4, progress4, sessions4))

        // 5. サピエンス全史（歴史/読書中/進捗40%）
        let book5 = Book(
            title: "サピエンス全史",
            author: "ユヴァル・ノア・ハラリ",
            totalPages: 506,
            genre: BookGenre.history.rawValue,
            isbn: "9784309226712"
        )
        book5.summary = "人類の歴史を壮大なスケールで描く話題作"

        let progress5 = ReadingProgress(currentPage: 200, status: .reading)
        progress5.startDate = Calendar.current.date(byAdding: .day, value: -20, to: Date())
        progress5.targetCompletionDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())

        let sessions5 = createOngoingBookSessions(book: book5, startDate: progress5.startDate!, currentPage: 200)

        booksData.append((book5, progress5, sessions5))

        // 6. 嫌われる勇気（自己啓発/読書中/進捗30%）
        let book6 = Book(
            title: "嫌われる勇気",
            author: "岸見一郎, 古賀史健",
            totalPages: 296,
            genre: BookGenre.selfImprovement.rawValue,
            isbn: "9784478025819"
        )
        book6.summary = "アドラー心理学を対話形式で学ぶベストセラー"

        let progress6 = ReadingProgress(currentPage: 90, status: .reading)
        progress6.startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())

        let sessions6 = createOngoingBookSessions(book: book6, startDate: progress6.startDate!, currentPage: 90)

        booksData.append((book6, progress6, sessions6))

        // 7. 君たちはどう生きるか（小説/未読）
        let book7 = Book(
            title: "君たちはどう生きるか",
            author: "吉野源三郎",
            totalPages: 320,
            genre: BookGenre.fiction.rawValue,
            isbn: "9784003315811"
        )
        book7.summary = "少年の成長を描く日本の名作"

        let progress7 = ReadingProgress(currentPage: 0, status: .notStarted)

        booksData.append((book7, progress7, []))

        // 8. 影響力の武器（ビジネス/未読）
        let book8 = Book(
            title: "影響力の武器",
            author: "ロバート・B・チャルディーニ",
            totalPages: 490,
            genre: BookGenre.business.rawValue,
            isbn: "9784414304220"
        )
        book8.summary = "人を動かす6つの原理を科学的に解説"

        let progress8 = ReadingProgress(currentPage: 0, status: .notStarted)

        booksData.append((book8, progress8, []))

        // 9. 三体（科学/中断/進捗20%）
        let book9 = Book(
            title: "三体",
            author: "劉慈欣",
            totalPages: 470,
            genre: BookGenre.science.rawValue,
            isbn: "9784152098047"
        )
        book9.summary = "中国発の壮大なSF小説"

        let progress9 = ReadingProgress(currentPage: 94, status: .paused)
        progress9.startDate = Calendar.current.date(byAdding: .day, value: -45, to: Date())

        let sessions9 = createPausedBookSessions(book: book9, startDate: progress9.startDate!, currentPage: 94)

        booksData.append((book9, progress9, sessions9))

        // 10. スタンフォード式 最高の睡眠（健康/完読/評価4）
        let book10 = Book(
            title: "スタンフォード式 最高の睡眠",
            author: "西野精治",
            totalPages: 251,
            genre: BookGenre.health.rawValue,
            isbn: "9784763136015"
        )
        book10.summary = "睡眠の質を高める科学的メソッド"

        let progress10 = ReadingProgress(currentPage: 251, status: .completed)
        progress10.startDate = Calendar.current.date(byAdding: .day, value: -50, to: Date())
        progress10.completedDate = Calendar.current.date(byAdding: .day, value: -42, to: Date())
        progress10.rating = 4
        progress10.review = "睡眠の科学的知見が豊富。実践的なアドバイスが役立つ。"

        let sessions10 = createCompletedBookSessions(book: book10, startDate: progress10.startDate!, endDate: progress10.completedDate!, totalPages: 251)

        booksData.append((book10, progress10, sessions10))

        return booksData
    }

    // MARK: - Session Creation Helpers

    /// 完読した本の読書セッションを生成
    private static func createCompletedBookSessions(book: Book, startDate: Date, endDate: Date, totalPages: Int) -> [ReadingSession] {
        var sessions: [ReadingSession] = []
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let pagesPerDay = totalPages / max(totalDays, 1)

        // 読書期間中のセッションを生成（1日おき程度）
        var currentPage = 0
        var currentDate = startDate

        while currentPage < totalPages && currentDate <= endDate {
            let sessionStart = Calendar.current.date(byAdding: .hour, value: Int.random(in: 19...21), to: currentDate) ?? currentDate
            let duration = TimeInterval(Int.random(in: 20...60) * 60) // 20-60分
            let sessionEnd = sessionStart.addingTimeInterval(duration)

            let pagesRead = min(Int.random(in: 15...30), totalPages - currentPage)

            let session = ReadingSession(startPage: currentPage, startTime: sessionStart)
            session.endSession(at: currentPage + pagesRead, endTime: sessionEnd)
            session.mood = [ReadingMood.excellent, .good, .good, .neutral].randomElement()
            session.concentration = Int.random(in: 3...5)

            sessions.append(session)

            currentPage += pagesRead
            currentDate = Calendar.current.date(byAdding: .day, value: Int.random(in: 1...2), to: currentDate) ?? currentDate
        }

        return sessions
    }

    /// 読書中の本のセッションを生成
    private static func createOngoingBookSessions(book: Book, startDate: Date, currentPage: Int) -> [ReadingSession] {
        var sessions: [ReadingSession] = []

        var page = 0
        var date = startDate

        // 開始日から現在まで数回のセッションを生成
        while page < currentPage && date <= Date() {
            let sessionStart = Calendar.current.date(byAdding: .hour, value: Int.random(in: 19...21), to: date) ?? date
            let duration = TimeInterval(Int.random(in: 25...45) * 60) // 25-45分
            let sessionEnd = sessionStart.addingTimeInterval(duration)

            let pagesRead = min(Int.random(in: 15...25), currentPage - page)

            let session = ReadingSession(startPage: page, startTime: sessionStart)
            session.endSession(at: page + pagesRead, endTime: sessionEnd)
            session.mood = [ReadingMood.good, .neutral, .excellent].randomElement()
            session.concentration = Int.random(in: 3...5)

            sessions.append(session)

            page += pagesRead
            date = Calendar.current.date(byAdding: .day, value: Int.random(in: 1...3), to: date) ?? date
        }

        return sessions
    }

    /// 中断した本のセッションを生成
    private static func createPausedBookSessions(book: Book, startDate: Date, currentPage: Int) -> [ReadingSession] {
        var sessions: [ReadingSession] = []

        // 最初の数セッションのみ生成
        var page = 0
        var date = startDate

        for _ in 0..<3 {
            let sessionStart = Calendar.current.date(byAdding: .hour, value: Int.random(in: 20...22), to: date) ?? date
            let duration = TimeInterval(Int.random(in: 15...30) * 60) // 15-30分（中断したので短め）
            let sessionEnd = sessionStart.addingTimeInterval(duration)

            let pagesRead = min(Int.random(in: 10...20), currentPage - page)

            let session = ReadingSession(startPage: page, startTime: sessionStart)
            session.endSession(at: page + pagesRead, endTime: sessionEnd)
            session.mood = [ReadingMood.tired, .distracted, .neutral].randomElement()
            session.concentration = Int.random(in: 2...3)

            sessions.append(session)

            page += pagesRead
            date = Calendar.current.date(byAdding: .day, value: Int.random(in: 2...4), to: date) ?? date
        }

        return sessions
    }
}
