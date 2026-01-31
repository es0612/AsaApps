//
//  StudySession.swift
//  AsaLanguageLearn
//
//  学習セッション記録
//

import Foundation
import SwiftData

/// 学習セッション記録
/// 1回の学習セッションの統計情報
@Model
final class StudySession {
    // MARK: - Properties

    @Attribute(.unique) var id: UUID

    /// セッション開始日時
    var startedAt: Date

    /// セッション終了日時
    var endedAt: Date?

    /// 練習したアイテム数
    var itemsPracticed: Int

    /// 正解数
    var correctCount: Int

    /// 不正解数
    var incorrectCount: Int

    /// 平均発音スコア
    var averageScore: Double

    /// セッションの種類（practice/review）
    var sessionTypeRawValue: String

    /// 関連するレッスンID
    var lessonId: UUID?

    // MARK: - Computed Properties

    var sessionType: SessionType {
        get { SessionType(rawValue: sessionTypeRawValue) ?? .practice }
        set { sessionTypeRawValue = newValue.rawValue }
    }

    /// セッション時間（秒）
    var durationSeconds: Int {
        guard let endedAt = endedAt else {
            return Int(Date().timeIntervalSince(startedAt))
        }
        return Int(endedAt.timeIntervalSince(startedAt))
    }

    /// セッション時間のフォーマット済み文字列
    var durationText: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }

    /// 正解率（0.0〜1.0）
    var correctRate: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0.0 }
        return Double(correctCount) / Double(total)
    }

    /// 正解率のパーセント表示
    var correctRateText: String {
        String(format: "%.0f%%", correctRate * 100)
    }

    /// セッションが完了しているか
    var isCompleted: Bool {
        endedAt != nil
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        sessionType: SessionType = .practice,
        lessonId: UUID? = nil
    ) {
        self.id = id
        self.startedAt = Date()
        self.itemsPracticed = 0
        self.correctCount = 0
        self.incorrectCount = 0
        self.averageScore = 0.0
        self.sessionTypeRawValue = sessionType.rawValue
        self.lessonId = lessonId
    }

    // MARK: - Methods

    /// セッションを終了
    func end() {
        endedAt = Date()
    }

    /// 結果を記録
    func recordResult(isCorrect: Bool, pronunciationScore: Double) {
        if isCorrect {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
        itemsPracticed += 1

        // 平均スコアの更新
        if itemsPracticed == 1 {
            averageScore = pronunciationScore
        } else {
            averageScore = averageScore
                + (pronunciationScore - averageScore) / Double(itemsPracticed)
        }
    }
}

// MARK: - SessionType

enum SessionType: String, CaseIterable, Codable, Sendable {
    case practice = "practice"
    case review = "review"

    var displayName: String {
        switch self {
        case .practice: return "練習"
        case .review: return "復習"
        }
    }

    var icon: String {
        switch self {
        case .practice: return "mic.fill"
        case .review: return "arrow.clockwise"
        }
    }
}

// MARK: - Sample Data

extension StudySession {
    static var sampleCompleted: StudySession {
        let session = StudySession(sessionType: .practice)
        session.correctCount = 8
        session.incorrectCount = 2
        session.itemsPracticed = 10
        session.averageScore = 0.78
        session.endedAt = session.startedAt.addingTimeInterval(300) // 5分後
        return session
    }

    static var sampleInProgress: StudySession {
        let session = StudySession(sessionType: .review)
        session.correctCount = 3
        session.incorrectCount = 1
        session.itemsPracticed = 4
        session.averageScore = 0.82
        return session
    }
}
