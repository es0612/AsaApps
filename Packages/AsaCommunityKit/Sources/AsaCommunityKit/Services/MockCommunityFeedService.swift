import Foundation

// MARK: - MockCommunityFeedService

/// バックエンドモックサービス（将来のCloudKit/API接続用の仮実装）
@MainActor
public final class MockCommunityFeedService: CommunityFeedServiceProtocol {

    public init() {}

    // MARK: - Fetch

    public func fetchLatestPosts(since: Date?) async throws -> [CommunityPost] {
        // ネットワーク遅延をシミュレート
        try await Task.sleep(for: .milliseconds(500))

        return [
            CommunityPost(
                title: "今週末の公園清掃のお知らせ",
                content: "今週日曜日の朝8時から中央公園の清掃活動を行います。軍手とゴミ袋は用意しますので、お気軽にご参加ください。",
                category: .event
            ),
            CommunityPost(
                title: "不用品をお譲りします",
                content: "子どもが大きくなったため、ベビーカーとチャイルドシートをお譲りします。状態は良好です。ご興味のある方はご連絡ください。",
                category: .giveaway
            ),
            CommunityPost(
                title: "おすすめの小児科を教えてください",
                content: "最近引っ越してきました。近くで評判の良い小児科があれば教えていただけると助かります。",
                category: .question
            ),
            CommunityPost(
                title: "回覧板: 夏祭り実行委員募集",
                content: "8月の夏祭りに向けて実行委員を募集しています。準備や当日の運営をお手伝いいただける方を探しています。",
                category: .circular
            ),
            CommunityPost(
                title: "子育てサークルメンバー募集中",
                content: "0〜3歳のお子さんがいるご家庭を対象に、毎週水曜日に公民館で子育てサークルを開催しています。",
                category: .parenting
            ),
        ]
    }

    public func fetchLatestEvents(since: Date?) async throws -> [CommunityEvent] {
        try await Task.sleep(for: .milliseconds(300))

        let calendar = Calendar.current
        let now = Date()

        return [
            CommunityEvent(
                title: "あさひ台夏祭り",
                eventDescription: "毎年恒例の夏祭り。盆踊り、屋台、花火大会を開催します。",
                location: "あさひ台中央公園",
                latitude: 35.6812,
                longitude: 139.7671,
                startDate: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
                endDate: calendar.date(byAdding: .day, value: 15, to: now) ?? now,
                maxParticipants: 500
            ),
            CommunityEvent(
                title: "防災訓練",
                eventDescription: "地震を想定した避難訓練を実施します。消火器の使い方や応急手当も学べます。",
                location: "あさひ台小学校",
                latitude: 35.6815,
                longitude: 139.7675,
                startDate: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                endDate: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                maxParticipants: 200
            ),
            CommunityEvent(
                title: "子ども会キャンプ",
                eventDescription: "小学生を対象とした日帰りキャンプ。バーベキューやゲーム大会を予定しています。",
                location: "市立キャンプ場",
                latitude: 35.6800,
                longitude: 139.7660,
                startDate: calendar.date(byAdding: .day, value: 21, to: now) ?? now,
                endDate: calendar.date(byAdding: .day, value: 21, to: now) ?? now,
                maxParticipants: 30
            ),
        ]
    }

    public func fetchSafetyAlerts() async throws -> [SafetyReport] {
        try await Task.sleep(for: .milliseconds(200))

        return [
            SafetyReport(
                title: "不審者目撃情報",
                reportDescription: "あさひ台3丁目付近で、声かけ事案が報告されています。お子様の登下校時にはご注意ください。",
                alertLevel: .warning,
                latitude: 35.6810,
                longitude: 139.7668,
                reporterName: "自治会防犯部"
            ),
            SafetyReport(
                title: "道路工事のお知らせ",
                reportDescription: "あさひ台1丁目のメイン通りで水道管工事が行われます。片側通行にご協力ください。",
                alertLevel: .info,
                latitude: 35.6808,
                longitude: 139.7665,
                reporterName: "市役所土木課"
            ),
        ]
    }

    // MARK: - Submit

    public func submitPost(_ post: CommunityPost) async throws {
        // モック: サーバー送信をシミュレート
        try await Task.sleep(for: .milliseconds(300))
    }

    public func submitEvent(_ event: CommunityEvent) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    public func submitSafetyReport(_ report: SafetyReport) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }
}
