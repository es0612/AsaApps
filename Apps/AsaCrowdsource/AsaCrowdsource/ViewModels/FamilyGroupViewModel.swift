//
//  FamilyGroupViewModel.swift
//  AsaCrowdsource
//
//  家族グループを管理するViewModel
//

import Foundation
import SwiftUI
import SwiftData

/// 家族グループViewModel
@MainActor
final class FamilyGroupViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var currentGroup: LocalFamilyGroup?
    @Published private(set) var userGroups: [LocalFamilyGroup] = []
    @Published private(set) var members: [LocalMember] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var dataService: LocalDataService?
    private let currentGroupKey = "AsaCrowdsource.CurrentGroupId"

    // MARK: - Computed Properties

    var hasGroup: Bool {
        currentGroup != nil
    }

    var groupName: String {
        currentGroup?.name ?? ""
    }

    var inviteCode: String {
        currentGroup?.formattedInviteCode ?? ""
    }

    var memberCount: Int {
        members.count
    }

    var isOwner: Bool {
        guard let group = currentGroup, let userId = currentUserId else { return false }
        return group.ownerId == userId
    }

    private var currentUserId: String? {
        UserDefaults.standard.string(forKey: "AsaCrowdsource.CurrentUserId")
    }

    // MARK: - Public Methods

    /// データサービスを設定
    func setDataService(_ service: LocalDataService) {
        self.dataService = service
    }

    /// ユーザーIDを保存
    func setCurrentUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: "AsaCrowdsource.CurrentUserId")
    }

    /// 初期データを読み込み
    func loadInitialData() async {
        guard let dataService = dataService, let userId = currentUserId else { return }

        isLoading = true
        do {
            // ユーザーのグループ一覧を取得
            userGroups = try await dataService.fetchUserGroups(userId: userId)

            // 保存された現在のグループを復元
            if let savedGroupIdString = UserDefaults.standard.string(forKey: currentGroupKey),
               let savedGroupId = UUID(uuidString: savedGroupIdString) {
                currentGroup = try await dataService.fetchGroup(id: savedGroupId)
            } else if let firstGroup = userGroups.first {
                currentGroup = firstGroup
                saveCurrentGroupId(firstGroup.id)
            }

            // メンバーを読み込み
            if let group = currentGroup {
                members = try await dataService.fetchMembers(groupId: group.id)
            }
        } catch {
            errorMessage = "データの読み込みに失敗しました: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// グループを作成
    func createGroup(name: String, description: String) async {
        guard let dataService = dataService, let userId = currentUserId else { return }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "グループ名を入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let group = try await dataService.createGroup(
                name: name,
                description: description,
                ownerId: userId
            )
            currentGroup = group
            userGroups.append(group)
            saveCurrentGroupId(group.id)

            // メンバーを更新
            members = try await dataService.fetchMembers(groupId: group.id)
        } catch {
            errorMessage = "グループの作成に失敗しました: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// 招待コードでグループに参加
    func joinGroup(inviteCode: String, displayName: String) async {
        guard let dataService = dataService, let userId = currentUserId else { return }
        guard !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "招待コードを入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let group = try await dataService.joinGroup(
                inviteCode: inviteCode,
                userId: userId,
                displayName: displayName
            )
            currentGroup = group
            if !userGroups.contains(where: { $0.id == group.id }) {
                userGroups.append(group)
            }
            saveCurrentGroupId(group.id)

            // メンバーを更新
            members = try await dataService.fetchMembers(groupId: group.id)
        } catch let error as DataServiceError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "グループへの参加に失敗しました: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// グループを切り替え
    func switchGroup(to group: LocalFamilyGroup) async {
        guard let dataService = dataService else { return }

        currentGroup = group
        saveCurrentGroupId(group.id)

        do {
            members = try await dataService.fetchMembers(groupId: group.id)
        } catch {
            errorMessage = "メンバーの読み込みに失敗しました"
        }
    }

    /// 招待コードを再生成
    func regenerateInviteCode() async {
        guard let dataService = dataService, let group = currentGroup else { return }

        do {
            let newCode = try await dataService.regenerateInviteCode(groupId: group.id)
            // グループを再取得して更新
            if let updatedGroup = try await dataService.fetchGroup(id: group.id) {
                currentGroup = updatedGroup
            }
        } catch {
            errorMessage = "招待コードの再生成に失敗しました"
        }
    }

    /// グループから離脱
    func leaveGroup() async {
        guard let dataService = dataService,
              let group = currentGroup,
              let userId = currentUserId else { return }

        isLoading = true
        do {
            try await dataService.leaveGroup(groupId: group.id, userId: userId)
            userGroups.removeAll { $0.id == group.id }

            // 別のグループに切り替え
            if let nextGroup = userGroups.first {
                currentGroup = nextGroup
                saveCurrentGroupId(nextGroup.id)
                members = try await dataService.fetchMembers(groupId: nextGroup.id)
            } else {
                currentGroup = nil
                clearCurrentGroupId()
                members = []
            }
        } catch {
            errorMessage = "グループからの離脱に失敗しました"
        }
        isLoading = false
    }

    /// グループを削除（オーナーのみ）
    func deleteGroup() async {
        guard let dataService = dataService,
              let group = currentGroup,
              let userId = currentUserId,
              isOwner else { return }

        isLoading = true
        do {
            try await dataService.deleteGroup(id: group.id, ownerId: userId)
            userGroups.removeAll { $0.id == group.id }

            // 別のグループに切り替え
            if let nextGroup = userGroups.first {
                currentGroup = nextGroup
                saveCurrentGroupId(nextGroup.id)
                members = try await dataService.fetchMembers(groupId: nextGroup.id)
            } else {
                currentGroup = nil
                clearCurrentGroupId()
                members = []
            }
        } catch {
            errorMessage = "グループの削除に失敗しました"
        }
        isLoading = false
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func saveCurrentGroupId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: currentGroupKey)
    }

    private func clearCurrentGroupId() {
        UserDefaults.standard.removeObject(forKey: currentGroupKey)
    }
}
