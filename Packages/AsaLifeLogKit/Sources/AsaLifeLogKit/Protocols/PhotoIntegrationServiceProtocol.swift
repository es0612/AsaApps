import Foundation

// MARK: - PhotoIntegrationServiceProtocol

/// 写真統合プロトコル
///
/// Photos フレームワークのラッパーとして、写真アセットの取得・サムネイル生成を提供する。
@MainActor
public protocol PhotoIntegrationServiceProtocol: Sendable {
    /// 写真ライブラリへのアクセス許可をリクエストする
    func requestAuthorization() async -> Bool

    /// 指定日の写真アセット情報を取得する
    func fetchPhotos(for date: Date) async throws -> [PhotoAssetInfo]

    /// 写真アセットのサムネイルデータを取得する
    func fetchThumbnail(assetIdentifier: String) async throws -> Data?
}
