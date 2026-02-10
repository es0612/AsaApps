import Foundation

// MARK: - プロフィール管理ViewModel

/// プロフィール編集とバッジ表示を管理
@Observable
@MainActor
public final class ProfileViewModel {

    // MARK: - Dependencies

    /// データサービス（DI）
    private let dataService: EduGameDataServiceProtocol

    // MARK: - Properties

    /// ユーザープロフィール
    public var profile: UserProfile?

    /// 解除済みのアチーブメント一覧
    public var unlockedBadges: [Achievement] = []

    /// 全バッジ定義一覧
    public var allBadges: [BadgeDefinition] = BadgeDefinition.allCases

    /// 編集モードフラグ
    public var isEditing: Bool = false

    /// 編集中の名前
    public var editName: String = ""

    /// 編集中のアバター絵文字
    public var editEmoji: String = ""

    /// 編集中の年齢
    public var editAge: Int = 5

    // MARK: - Init

    public init(dataService: EduGameDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    /// プロフィールとバッジ情報を読み込む
    public func loadProfile() {
        do {
            let loadedProfile = try dataService.getOrCreateProfile()
            profile = loadedProfile
            unlockedBadges = loadedProfile.achievements
        } catch {
            profile = nil
            unlockedBadges = []
        }
    }

    /// プロフィールの変更を保存する
    public func saveProfile() {
        guard let profile else { return }

        profile.name = editName
        profile.avatarEmoji = editEmoji
        profile.age = editAge
        profile.updatedAt = Date()

        do {
            try dataService.updateProfile(profile)
            isEditing = false
        } catch {
            // 保存失敗時は編集モードを維持
        }
    }

    /// 編集モードを開始し、現在の値を編集フィールドに反映
    public func startEditing() {
        guard let profile else { return }

        editName = profile.name
        editEmoji = profile.avatarEmoji
        editAge = profile.age
        isEditing = true
    }

    /// 編集をキャンセルして編集モードを終了
    public func cancelEditing() {
        isEditing = false

        // 編集フィールドを元に戻す
        if let profile {
            editName = profile.name
            editEmoji = profile.avatarEmoji
            editAge = profile.age
        }
    }
}
