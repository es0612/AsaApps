//
//  User.swift
//  AsaCrowdsource
//
//  ユーザー（認証情報）のモデル
//

import Foundation

/// 認証済みユーザー情報
struct User: Identifiable, Codable, Equatable, Sendable {
    // MARK: - Properties

    /// ユーザーID
    let id: String

    /// メールアドレス
    let email: String

    /// 表示名
    var displayName: String

    /// プロフィール画像URL
    var photoURL: String?

    /// 作成日時
    let createdAt: Date

    /// 最終ログイン日時
    var lastLoginAt: Date

    // MARK: - Initializer

    init(
        id: String,
        email: String,
        displayName: String,
        photoURL: String? = nil,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }

    // MARK: - Methods

    /// 最終ログイン日時を更新したコピーを返す
    func withUpdatedLastLogin() -> User {
        var copy = self
        copy.lastLoginAt = Date()
        return copy
    }
}

// MARK: - Sample Data

extension User {
    /// プレビュー用サンプルユーザー
    static var sampleUser: User {
        User(
            id: "user1",
            email: "papa@example.com",
            displayName: "パパ"
        )
    }

    /// 匿名ユーザー（ゲストモード用）
    static var anonymous: User {
        User(
            id: "anonymous",
            email: "",
            displayName: "ゲスト"
        )
    }
}
