import Testing
import Foundation
@testable import AsaLifeLogKit

// MARK: - LifeLogError Tests

@Suite("LifeLogError")
struct LifeLogErrorTests {
    @Test("dataNotFound のエラーメッセージが正しい")
    func dataNotFound() {
        let error = LifeLogError.dataNotFound
        #expect(error.errorDescription == "データが見つかりませんでした")
    }

    @Test("saveFailed のエラーメッセージが underlying を含む")
    func saveFailed() {
        let underlying = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])
        let error = LifeLogError.saveFailed(underlying: underlying)
        #expect(error.errorDescription?.contains("保存に失敗しました") == true)
        #expect(error.errorDescription?.contains("テストエラー") == true)
    }

    @Test("locationNotAvailable のエラーメッセージが正しい")
    func locationNotAvailable() {
        let error = LifeLogError.locationNotAvailable
        #expect(error.errorDescription == "位置情報が利用できません")
    }

    @Test("photoAccessDenied のエラーメッセージが正しい")
    func photoAccessDenied() {
        let error = LifeLogError.photoAccessDenied
        #expect(error.errorDescription == "写真ライブラリへのアクセスが拒否されました")
    }

    @Test("activityNotAvailable のエラーメッセージが正しい")
    func activityNotAvailable() {
        let error = LifeLogError.activityNotAvailable
        #expect(error.errorDescription == "アクティビティ認識が利用できません")
    }

    @Test("exportFailed のエラーメッセージが正しい")
    func exportFailed() {
        let error = LifeLogError.exportFailed
        #expect(error.errorDescription == "データのエクスポートに失敗しました")
    }

    @Test("invalidEntry のエラーメッセージが reason を含む")
    func invalidEntry() {
        let error = LifeLogError.invalidEntry(reason: "タイトルが空です")
        #expect(error.errorDescription?.contains("無効なエントリーです") == true)
        #expect(error.errorDescription?.contains("タイトルが空です") == true)
    }
}
