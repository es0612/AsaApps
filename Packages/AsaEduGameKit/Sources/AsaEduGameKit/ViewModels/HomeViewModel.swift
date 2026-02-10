import Foundation

// MARK: - ホーム画面ViewModel

/// ホーム画面のゲームモード選択とプロフィール表示を管理
@Observable
@MainActor
public final class HomeViewModel {

    // MARK: - Dependencies

    /// データサービス（DI）
    private let dataService: EduGameDataServiceProtocol

    // MARK: - Properties

    /// ユーザープロフィール
    public var profile: UserProfile?

    /// 読み込み中フラグ
    public var isLoading: Bool = false

    /// エラーメッセージ
    public var errorMessage: String?

    // MARK: - Init

    public init(dataService: EduGameDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Methods

    /// プロフィールを読み込む（なければデフォルト作成）
    public func loadProfile() {
        isLoading = true
        errorMessage = nil

        do {
            profile = try dataService.getOrCreateProfile()
        } catch {
            errorMessage = "プロフィールのよみこみにしっぱいしました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// ゲームモードを選択して返す
    public func selectGameMode(_ mode: GameMode) -> GameMode {
        return mode
    }
}
