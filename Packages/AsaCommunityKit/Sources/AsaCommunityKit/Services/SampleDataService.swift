import Foundation
import SwiftData

// MARK: - SampleDataService

/// サンプルデータ一括生成サービス
@MainActor
public final class SampleDataService {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - サンプルデータ一括作成

    /// すべてのサンプルデータを生成して保存する
    public func loadSampleData() throws {
        let community = createCommunity()
        let profile = createProfile()
        let posts = createPosts(community: community, author: profile)
        let events = createEvents(community: community)
        let safetyReports = createSafetyReports()
        let shelters = createShelters()
        let schedules = createGarbageSchedules()
        let businesses = createBusinesses()
        let settings = createSettings()

        // コンテキストに挿入
        modelContext.insert(community)
        modelContext.insert(profile)
        for post in posts { modelContext.insert(post) }
        for event in events { modelContext.insert(event) }
        for report in safetyReports { modelContext.insert(report) }
        for shelter in shelters { modelContext.insert(shelter) }
        for schedule in schedules { modelContext.insert(schedule) }
        for business in businesses { modelContext.insert(business) }
        modelContext.insert(settings)

        try modelContext.save()
    }

    // MARK: - Community

    private func createCommunity() -> Community {
        Community(
            name: "あさひ台自治会",
            area: "あさひ台1〜5丁目",
            welcomeMessage: "あさひ台自治会へようこそ！地域のつながりを大切に、安心して暮らせるまちづくりを一緒に進めましょう。",
            memberCount: 342,
            latitude: 35.6812,
            longitude: 139.7671
        )
    }

    // MARK: - Profile

    private func createProfile() -> CommunityProfile {
        let profile = CommunityProfile(
            displayName: "朝活パパ",
            bio: "あさひ台在住のエンジニアです。朝活と子育てを楽しんでいます。地域のことなら何でも聞いてください！"
        )
        profile.isVerified = true
        profile.postCount = 8
        profile.helpfulCount = 15
        return profile
    }

    // MARK: - Posts

    private func createPosts(community: Community, author: CommunityProfile) -> [CommunityPost] {
        let calendar = Calendar.current
        let now = Date()

        let postsData: [(String, String, PostCategory, Int)] = [
            (
                "今週末の公園清掃ボランティア",
                "今週日曜日の朝8時から中央公園の清掃活動を行います。軍手とゴミ袋は用意しますので、お気軽にご参加ください。雨天の場合は翌週に延期します。",
                .event,
                -1
            ),
            (
                "おすすめの小児科を教えてください",
                "最近あさひ台に引っ越してきました。3歳と1歳の子どもがいます。近くで評判の良い小児科があれば教えていただけると助かります。",
                .question,
                -2
            ),
            (
                "ベビーカーお譲りします",
                "子どもが大きくなったため、コンビのベビーカー（2022年製）をお譲りします。状態良好です。引き取りに来ていただける方を優先します。",
                .giveaway,
                -3
            ),
            (
                "自転車用ヘルメット探しています",
                "小学1年生用の自転車ヘルメットを探しています。新品でなくても構いません。お心当たりの方はご連絡ください。",
                .wanted,
                -4
            ),
            (
                "回覧板: 7月度自治会費のご案内",
                "7月度の自治会費（月額500円）の集金日は7月10日〜15日です。班長さんが各戸を回りますので、ご準備をお願いいたします。",
                .circular,
                -5
            ),
            (
                "不審者目撃情報にご注意ください",
                "昨日夕方、あさひ台3丁目のコンビニ付近で子どもへの声かけ事案が発生しました。お子様の登下校時にはご注意ください。",
                .safety,
                -6
            ),
            (
                "子育てサークルメンバー募集",
                "毎週水曜日10時から公民館で0〜3歳児を対象とした子育てサークル「ひまわり」を開催しています。見学歓迎です！",
                .parenting,
                -7
            ),
            (
                "あさひ台の桜が見頃です",
                "中央公園の桜が満開になりました。今年は開花が早いですね。週末のお花見にぜひどうぞ。ゴミは各自お持ち帰りでお願いします。",
                .general,
                -8
            ),
        ]

        return postsData.map { title, content, category, dayOffset in
            let post = CommunityPost(
                title: title,
                content: content,
                category: category
            )
            post.createdAt = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            post.updatedAt = post.createdAt
            post.community = community
            post.author = author
            post.likeCount = Int.random(in: 0...20)
            post.commentCount = Int.random(in: 0...8)
            return post
        }
    }

    // MARK: - Events

    private func createEvents(community: Community) -> [CommunityEvent] {
        let calendar = Calendar.current
        let now = Date()

        return [
            {
                let event = CommunityEvent(
                    title: "あさひ台夏祭り",
                    eventDescription: "毎年恒例の夏祭りです。盆踊り大会、屋台、子ども向けゲーム、打ち上げ花火など盛りだくさんの内容です。浴衣でのご参加も歓迎です。",
                    location: "あさひ台中央公園",
                    latitude: 35.6812,
                    longitude: 139.7671,
                    startDate: calendar.date(byAdding: .day, value: 30, to: now) ?? now,
                    endDate: calendar.date(byAdding: .day, value: 31, to: now) ?? now,
                    maxParticipants: 500
                )
                event.community = community
                return event
            }(),
            {
                let event = CommunityEvent(
                    title: "防災訓練",
                    eventDescription: "地震・火災を想定した避難訓練を実施します。消火器の使い方、AEDの操作方法、応急手当の実習もあります。",
                    location: "あさひ台小学校 校庭",
                    latitude: 35.6815,
                    longitude: 139.7675,
                    startDate: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
                    endDate: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
                    maxParticipants: 200
                )
                event.community = community
                return event
            }(),
            {
                let event = CommunityEvent(
                    title: "子ども会サマーキャンプ",
                    eventDescription: "小学生を対象とした日帰りキャンプです。バーベキュー、自然観察、キャンプファイヤーを予定しています。保護者の付き添いも歓迎です。",
                    location: "市立森林公園キャンプ場",
                    latitude: 35.6800,
                    longitude: 139.7660,
                    startDate: calendar.date(byAdding: .day, value: 45, to: now) ?? now,
                    endDate: calendar.date(byAdding: .day, value: 45, to: now) ?? now,
                    maxParticipants: 30
                )
                event.community = community
                return event
            }(),
        ]
    }

    // MARK: - Safety Reports

    private func createSafetyReports() -> [SafetyReport] {
        [
            SafetyReport(
                title: "不審者目撃情報",
                reportDescription: "あさひ台3丁目のコンビニ付近で、下校中の児童に声をかける不審な男性が目撃されました。30代くらい、黒いパーカー着用。警察に通報済みです。",
                alertLevel: .warning,
                latitude: 35.6810,
                longitude: 139.7668,
                reporterName: "自治会防犯部"
            ),
            SafetyReport(
                title: "水道管工事に伴う片側通行",
                reportDescription: "あさひ台1丁目メイン通りで水道管更新工事が行われます。期間中は片側通行となりますのでご注意ください。工事期間: 7/15〜7/31",
                alertLevel: .info,
                latitude: 35.6808,
                longitude: 139.7665,
                reporterName: "市役所土木課"
            ),
        ]
    }

    // MARK: - Evacuation Shelters

    private func createShelters() -> [EvacuationShelter] {
        [
            EvacuationShelter(
                name: "あさひ台小学校",
                address: "あさひ台2-10-1",
                latitude: 35.6815,
                longitude: 139.7675,
                capacity: 500,
                hasWater: true,
                hasFood: true,
                hasMedical: true,
                hasElectricity: true,
                phoneNumber: "03-1234-5678"
            ),
            EvacuationShelter(
                name: "あさひ台公民館",
                address: "あさひ台3-5-2",
                latitude: 35.6808,
                longitude: 139.7680,
                capacity: 200,
                hasWater: true,
                hasFood: false,
                hasMedical: false,
                hasElectricity: true,
                phoneNumber: "03-2345-6789"
            ),
            EvacuationShelter(
                name: "市立総合体育館",
                address: "あさひ台5-1-1",
                latitude: 35.6820,
                longitude: 139.7690,
                capacity: 1000,
                hasWater: true,
                hasFood: true,
                hasMedical: true,
                hasElectricity: true,
                phoneNumber: "03-3456-7890"
            ),
        ]
    }

    // MARK: - Garbage Schedules

    private func createGarbageSchedules() -> [GarbageSchedule] {
        [
            // 燃えるゴミ: 毎週月曜・木曜
            GarbageSchedule(garbageType: .burnable, weekday: 2, note: "朝8時までに出してください"),
            GarbageSchedule(garbageType: .burnable, weekday: 5, note: "朝8時までに出してください"),
            // プラスチック: 毎週水曜
            GarbageSchedule(garbageType: .recyclePlastic, weekday: 4, note: "軽く洗って出してください"),
            // 古紙: 毎週火曜
            GarbageSchedule(garbageType: .recyclePaper, weekday: 3, note: "紐で束ねて出してください"),
            // 燃えないゴミ: 第2・第4金曜
            GarbageSchedule(garbageType: .nonBurnable, weekday: 6, weekOfMonth: 2, note: "指定袋に入れて出してください"),
        ]
    }

    // MARK: - Local Businesses

    private func createBusinesses() -> [LocalBusiness] {
        [
            LocalBusiness(
                name: "パン工房 あさひ",
                businessDescription: "朝5時から焼きたてパンを販売。地元小麦を使用した食パンが人気です。",
                category: .restaurant,
                address: "あさひ台1-3-5",
                latitude: 35.6811,
                longitude: 139.7670,
                phoneNumber: "03-1111-2222",
                businessHours: "5:00〜18:00",
                closedDays: "日曜・祝日"
            ),
            LocalBusiness(
                name: "スーパーまるやま",
                businessDescription: "地元密着のスーパーマーケット。新鮮な野菜と魚が自慢です。",
                category: .grocery,
                address: "あさひ台2-7-1",
                latitude: 35.6813,
                longitude: 139.7673,
                phoneNumber: "03-2222-3333",
                businessHours: "9:00〜21:00",
                closedDays: "年中無休"
            ),
            LocalBusiness(
                name: "田中クリニック（小児科・内科）",
                businessDescription: "地域のかかりつけ医。小児科と内科を診療。予防接種も対応しています。",
                category: .medical,
                address: "あさひ台3-2-8",
                latitude: 35.6809,
                longitude: 139.7678,
                phoneNumber: "03-3333-4444",
                businessHours: "9:00〜12:00 / 15:00〜18:00",
                closedDays: "水曜午後・日曜・祝日"
            ),
            LocalBusiness(
                name: "学習塾 あさひゼミナール",
                businessDescription: "小中学生対象の学習塾。少人数制で丁寧に指導します。無料体験授業あり。",
                category: .education,
                address: "あさひ台1-8-3",
                latitude: 35.6814,
                longitude: 139.7667,
                phoneNumber: "03-4444-5555",
                businessHours: "15:00〜21:00",
                closedDays: "日曜"
            ),
            LocalBusiness(
                name: "美容室 Bloom",
                businessDescription: "カット・カラー・パーマなど。キッズスペースも完備でお子様連れでも安心です。",
                category: .beauty,
                address: "あさひ台4-1-6",
                latitude: 35.6816,
                longitude: 139.7682,
                phoneNumber: "03-5555-6666",
                businessHours: "10:00〜19:00",
                closedDays: "火曜"
            ),
        ]
    }

    // MARK: - Settings

    private func createSettings() -> CommunitySettings {
        CommunitySettings(
            isGarbageReminderEnabled: true,
            reminderHour: 21,
            isEventNotificationEnabled: true,
            isSafetyAlertEnabled: true,
            mapRadiusMeters: 1000
        )
    }
}
