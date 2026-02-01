//
//  DiaryEntry.swift
//  AsaVRDiary
//
//  Swift Data モデル: 日記エントリー
//

import Foundation
import SwiftData

/// 日記エントリー
@Model
final class DiaryEntry {
    // MARK: - Properties

    /// 一意識別子
    @Attribute(.unique) var id: UUID

    /// タイトル
    var title: String

    /// 本文
    var content: String

    /// 日記の日付（エントリーが属する日）
    var date: Date

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    /// カテゴリ（Raw Value で保存）
    var categoryRawValue: String

    /// 気分（Raw Value で保存）
    var moodRawValue: String

    /// 気分の強度（1-5）
    var moodIntensity: Int

    /// VR空間でのX座標（カスタム配置用）
    var vrPositionX: Float?

    /// VR空間でのY座標（カスタム配置用）
    var vrPositionY: Float?

    /// VR空間でのZ座標（カスタム配置用）
    var vrPositionZ: Float?

    /// お気に入りフラグ
    var isFavorite: Bool

    // MARK: - Computed Properties

    /// カテゴリ
    var category: DiaryCategory {
        get { DiaryCategory(rawValue: categoryRawValue) ?? .daily }
        set { categoryRawValue = newValue.rawValue }
    }

    /// 気分
    var mood: DiaryMood {
        get { DiaryMood(rawValue: moodRawValue) ?? .neutral }
        set { moodRawValue = newValue.rawValue }
    }

    /// VR空間での位置が設定されているか
    var hasCustomVRPosition: Bool {
        vrPositionX != nil && vrPositionY != nil && vrPositionZ != nil
    }

    /// 本文のプレビュー（最初の100文字）
    var contentPreview: String {
        if content.count <= 100 {
            return content
        }
        return String(content.prefix(100)) + "..."
    }

    /// 日付のフォーマット済み文字列
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    /// 作成日時のフォーマット済み文字列
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        date: Date = Date(),
        category: DiaryCategory = .daily,
        mood: DiaryMood = .neutral,
        moodIntensity: Int = 3,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.createdAt = Date()
        self.updatedAt = Date()
        self.categoryRawValue = category.rawValue
        self.moodRawValue = mood.rawValue
        self.moodIntensity = min(5, max(1, moodIntensity))
        self.isFavorite = isFavorite
        self.vrPositionX = nil
        self.vrPositionY = nil
        self.vrPositionZ = nil
    }

    // MARK: - Methods

    /// 更新日時を現在時刻に設定
    func touch() {
        updatedAt = Date()
    }

    /// VR位置を設定
    func setVRPosition(x: Float, y: Float, z: Float) {
        vrPositionX = x
        vrPositionY = y
        vrPositionZ = z
        touch()
    }

    /// VR位置をリセット
    func resetVRPosition() {
        vrPositionX = nil
        vrPositionY = nil
        vrPositionZ = nil
        touch()
    }
}

// MARK: - Equatable

extension DiaryEntry: Equatable {
    static func == (lhs: DiaryEntry, rhs: DiaryEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension DiaryEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
