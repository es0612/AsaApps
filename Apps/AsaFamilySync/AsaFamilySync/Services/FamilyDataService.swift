import Foundation

/// 家族データサービスのプロトコル
/// FirestoreとUserDefaults両方に対応するための抽象化レイヤー
protocol FamilyDataService {
    /// 家族グループを作成
    /// - Parameters:
    ///   - name: グループ名
    ///   - description: 説明（オプション）
    ///   - ownerId: オーナーのユーザーID
    ///   - ownerName: オーナーの名前
    ///   - ownerEmail: オーナーのメールアドレス
    /// - Returns: 作成された家族グループとそのID
    /// - Throws: 作成に失敗した場合
    func createFamilyGroup(
        name: String,
        description: String?,
        ownerId: String,
        ownerName: String,
        ownerEmail: String
    ) async throws -> (group: FamilyGroup, groupId: String)

    /// 招待コードで家族グループに参加
    /// - Parameters:
    ///   - inviteCode: 招待コード
    ///   - userId: 参加するユーザーID
    ///   - userName: ユーザー名
    ///   - userEmail: ユーザーのメールアドレス
    /// - Returns: 参加した家族グループとそのID
    /// - Throws: 参加に失敗した場合
    func joinFamilyGroup(
        inviteCode: String,
        userId: String,
        userName: String,
        userEmail: String
    ) async throws -> (group: FamilyGroup, groupId: String)

    /// 家族グループを取得
    /// - Parameter groupId: グループID
    /// - Returns: 家族グループ
    /// - Throws: 取得に失敗した場合
    func fetchFamilyGroup(groupId: String) async throws -> FamilyGroup

    /// 家族グループのメンバーを取得
    /// - Parameter groupId: グループID
    /// - Returns: メンバーのリスト
    /// - Throws: 取得に失敗した場合
    func fetchFamilyMembers(groupId: String) async throws -> [FamilyMember]

    /// メンバーを削除
    /// - Parameters:
    ///   - groupId: グループID
    ///   - memberId: メンバーのユーザーID
    /// - Throws: 削除に失敗した場合
    func removeMember(groupId: String, memberId: String) async throws

    /// メンバーの権限を変更
    /// - Parameters:
    ///   - groupId: グループID
    ///   - memberId: メンバーのユーザーID
    ///   - newRole: 新しい権限
    /// - Throws: 変更に失敗した場合
    func updateMemberRole(groupId: String, memberId: String, newRole: MemberRole) async throws

    /// 招待コードを再生成
    /// - Parameter groupId: グループID
    /// - Returns: 新しい招待コード
    /// - Throws: 更新に失敗した場合
    func regenerateInviteCode(groupId: String) async throws -> String

    /// 家族グループから退出
    /// - Parameters:
    ///   - groupId: グループID
    ///   - userId: 退出するユーザーID
    /// - Throws: 退出に失敗した場合
    func leaveFamilyGroup(groupId: String, userId: String) async throws

    // MARK: - イベント関連

    /// イベントを作成
    /// - Parameters:
    ///   - groupId: グループID
    ///   - event: イベント情報
    /// - Returns: 作成されたイベントのID
    /// - Throws: 作成に失敗した場合
    func createEvent(groupId: String, event: FamilyEvent) async throws -> String

    /// イベントを更新
    /// - Parameters:
    ///   - groupId: グループID
    ///   - eventId: イベントID
    ///   - event: 更新するイベント情報
    /// - Throws: 更新に失敗した場合
    func updateEvent(groupId: String, eventId: String, event: FamilyEvent) async throws

    /// イベントを削除
    /// - Parameters:
    ///   - groupId: グループID
    ///   - eventId: イベントID
    /// - Throws: 削除に失敗した場合
    func deleteEvent(groupId: String, eventId: String) async throws

    /// イベント一覧を取得
    /// - Parameter groupId: グループID
    /// - Returns: イベントのリスト
    /// - Throws: 取得に失敗した場合
    func fetchEvents(groupId: String) async throws -> [FamilyEvent]

    /// 特定の期間のイベントを取得
    /// - Parameters:
    ///   - groupId: グループID
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    /// - Returns: 指定期間のイベントリスト
    /// - Throws: 取得に失敗した場合
    func fetchEvents(groupId: String, from startDate: Date, to endDate: Date) async throws -> [FamilyEvent]
}

/// データサービスのエラー
enum DataServiceError: Error, LocalizedError {
    case invalidInviteCode
    case groupNotFound
    case memberNotFound
    case maxMembersReached
    case alreadyMember
    case permissionDenied
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidInviteCode:
            return "招待コードが無効です"
        case .groupNotFound:
            return "グループが見つかりません"
        case .memberNotFound:
            return "メンバーが見つかりません"
        case .maxMembersReached:
            return "このグループは最大人数に達しています"
        case .alreadyMember:
            return "既にこのグループのメンバーです"
        case .permissionDenied:
            return "この操作を実行する権限がありません"
        case .unknown(let message):
            return "エラー: \(message)"
        }
    }
}
