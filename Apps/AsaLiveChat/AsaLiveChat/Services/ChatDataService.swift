//
//  ChatDataService.swift
//  AsaLiveChat
//
//  Swift Dataを使用したチャットデータの永続化サービス
//

import Foundation
import SwiftData

/// チャットデータの永続化を管理するサービス
///
/// チャットルーム、メッセージ、ユーザー設定の
/// CRUD操作を一元管理します。
///
/// ## 使用例
/// ```swift
/// let dataService = ChatDataService(modelContext: context)
/// let rooms = dataService.fetchAllRooms()
/// dataService.createRoom(name: "家族チャット")
/// ```
@MainActor
@Observable
final class ChatDataService {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Room Operations

    /// すべてのルームを取得
    func fetchAllRooms() -> [ChatRoom] {
        let descriptor = FetchDescriptor<ChatRoom>(
            sortBy: [SortDescriptor(\.lastMessageAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("ルームの取得に失敗: \(error)")
            return []
        }
    }

    /// ルームコードでルームを検索
    func findRoom(byCode code: String) -> ChatRoom? {
        let upperCode = code.uppercased()
        let descriptor = FetchDescriptor<ChatRoom>(
            predicate: #Predicate<ChatRoom> { room in
                room.roomCode == upperCode
            }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("ルームの検索に失敗: \(error)")
            return nil
        }
    }

    /// ルームを作成
    @discardableResult
    func createRoom(name: String) -> ChatRoom {
        let room = ChatRoom(name: name)
        modelContext.insert(room)
        save()
        return room
    }

    /// ルームを削除
    func deleteRoom(_ room: ChatRoom) {
        modelContext.delete(room)
        save()
    }

    /// ルームを更新
    func updateRoom(_ room: ChatRoom) {
        save()
    }

    // MARK: - Message Operations

    /// ルーム内のメッセージを取得
    func fetchMessages(for room: ChatRoom) -> [Message] {
        let roomId = room.id
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { message in
                message.room?.id == roomId
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("メッセージの取得に失敗: \(error)")
            return []
        }
    }

    /// メッセージを作成・追加
    @discardableResult
    func createMessage(
        content: String,
        senderName: String,
        senderId: String,
        isSentByMe: Bool,
        room: ChatRoom
    ) -> Message {
        let message = Message(
            content: content,
            senderName: senderName,
            senderId: senderId,
            isSentByMe: isSentByMe,
            room: room
        )

        modelContext.insert(message)
        room.addMessage(message)
        save()

        return message
    }

    /// メッセージを削除
    func deleteMessage(_ message: Message) {
        modelContext.delete(message)
        save()
    }

    /// ルーム内のメッセージを既読に更新
    func markMessagesAsRead(in room: ChatRoom) {
        room.markAsRead()
        save()
    }

    // MARK: - User Settings Operations

    /// ユーザー設定を取得（なければ作成）
    func getOrCreateUserSettings() -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            let results = try modelContext.fetch(descriptor)
            if let existing = results.first {
                return existing
            }
        } catch {
            print("設定の取得に失敗: \(error)")
        }

        // 存在しない場合は新規作成
        let newSettings = UserSettings.createDefault()
        modelContext.insert(newSettings)
        save()

        return newSettings
    }

    /// ユーザー設定を更新
    func updateUserSettings(_ settings: UserSettings) {
        settings.update()
        save()
    }

    // MARK: - Save

    /// 変更を保存
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("保存に失敗: \(error)")
        }
    }
}

// MARK: - Chat Data Error

/// チャットデータ操作のエラー
enum ChatDataError: Error, LocalizedError {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case roomNotFound
    case invalidRoomCode

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "データの取得に失敗しました: \(message)"
        case .saveFailed(let message):
            return "データの保存に失敗しました: \(message)"
        case .deleteFailed(let message):
            return "データの削除に失敗しました: \(message)"
        case .roomNotFound:
            return "ルームが見つかりません"
        case .invalidRoomCode:
            return "無効なルームコードです"
        }
    }
}
