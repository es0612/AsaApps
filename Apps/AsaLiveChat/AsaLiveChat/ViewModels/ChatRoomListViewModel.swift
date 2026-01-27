//
//  ChatRoomListViewModel.swift
//  AsaLiveChat
//
//  チャットルーム一覧のViewModel
//

import Foundation

/// チャットルーム一覧を管理するViewModel
///
/// ルームの作成、削除、一覧表示を管理します。
@MainActor
@Observable
final class ChatRoomListViewModel {
    // MARK: - Dependencies

    let dataService: ChatDataService

    // MARK: - State

    /// ルーム一覧
    private(set) var rooms: [ChatRoom] = []

    /// 読み込み中フラグ
    private(set) var isLoading = false

    /// エラーメッセージ
    private(set) var errorMessage: String?

    // MARK: - UI State

    /// ルーム作成シート表示フラグ
    var showingCreateRoom = false

    /// ルーム参加シート表示フラグ
    var showingJoinRoom = false

    /// 削除確認アラート表示フラグ
    var showingDeleteAlert = false

    /// 削除対象のルーム
    var roomToDelete: ChatRoom?

    /// 新規ルーム名
    var newRoomName = ""

    /// 参加用ルームコード
    var joinRoomCode = ""

    // MARK: - Computed Properties

    /// 未読メッセージの総数
    var totalUnreadCount: Int {
        rooms.reduce(0) { $0 + $1.unreadCount }
    }

    /// ルームが空かどうか
    var isEmpty: Bool {
        rooms.isEmpty
    }

    // MARK: - Initialization

    init(dataService: ChatDataService) {
        self.dataService = dataService
        loadRooms()
    }

    // MARK: - Methods

    /// ルーム一覧を読み込み
    func loadRooms() {
        isLoading = true
        errorMessage = nil

        rooms = dataService.fetchAllRooms()

        isLoading = false
    }

    /// ルームを作成
    @discardableResult
    func createRoom() -> ChatRoom? {
        let trimmedName = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "ルーム名を入力してください"
            return nil
        }

        let room = dataService.createRoom(name: trimmedName)
        loadRooms()

        // 入力をリセット
        newRoomName = ""
        showingCreateRoom = false

        return room
    }

    /// ルームコードでルームに参加
    func joinRoom() -> ChatRoom? {
        let trimmedCode = joinRoomCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard trimmedCode.count == 6 else {
            errorMessage = "ルームコードは6文字です"
            return nil
        }

        // 既存のルームを検索
        if let existingRoom = dataService.findRoom(byCode: trimmedCode) {
            joinRoomCode = ""
            showingJoinRoom = false
            return existingRoom
        }

        // 見つからない場合は新規作成（モック動作）
        let room = ChatRoom(name: "ルーム \(trimmedCode)", roomCode: trimmedCode)
        dataService.createRoom(name: room.name)
        loadRooms()

        joinRoomCode = ""
        showingJoinRoom = false

        return dataService.findRoom(byCode: trimmedCode)
    }

    /// ルームを削除
    func deleteRoom(_ room: ChatRoom) {
        dataService.deleteRoom(room)
        loadRooms()
        roomToDelete = nil
    }

    /// 削除確認を表示
    func confirmDelete(_ room: ChatRoom) {
        roomToDelete = room
        showingDeleteAlert = true
    }

    /// エラーをクリア
    func clearError() {
        errorMessage = nil
    }
}
