import Foundation
import SwiftData

/// サンプルデータサービス - デモ動画撮影用の山田家家系図データを生成
@MainActor
public final class SampleDataService {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initializer

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// サンプルデータを一括投入（山田家 4世代15人）
    public func loadSampleData() throws {
        // 1. 家系図を作成
        let tree = FamilyTree(
            name: "山田家の家系図",
            notes: "4世代にわたる山田家の歴史を記録した家系図です"
        )
        modelContext.insert(tree)

        // 2. 全メンバーを作成・挿入
        let members = createAllMembers()
        for member in members {
            modelContext.insert(member)
            tree.addMember(member)
        }

        // 3. 親子関係を設定
        setupParentChildRelationships(members)

        // 4. 婚姻関係を設定
        try setupMarriages(members)

        // 5. 一括保存
        try modelContext.save()
    }

    // MARK: - Private Methods

    /// 全15人のメンバーを作成
    private func createAllMembers() -> [FamilyMember] {
        // --- 第1世代（祖父母） ---
        let taro = FamilyMember(
            firstName: "太郎",
            lastName: "山田",
            gender: .male,
            birthDate: makeDate(year: 1935, month: 3, day: 15),
            deathDate: makeDate(year: 2020, month: 11, day: 8),
            birthPlace: "東京都",
            notes: "家系図の始祖。大工の棟梁として地域で活躍した"
        )

        let hanako = FamilyMember(
            firstName: "花子",
            lastName: "山田",
            gender: .female,
            birthDate: makeDate(year: 1938, month: 7, day: 22),
            birthPlace: "神奈川県",
            notes: "旧姓: 佐藤。茶道を50年以上続けている"
        )

        // --- 第2世代（親） ---
        let ichiro = FamilyMember(
            firstName: "一郎",
            lastName: "山田",
            gender: .male,
            birthDate: makeDate(year: 1962, month: 5, day: 20),
            birthPlace: "東京都",
            notes: "長男。建設会社を経営している"
        )

        let misaki = FamilyMember(
            firstName: "美咲",
            lastName: "山田",
            gender: .female,
            birthDate: makeDate(year: 1965, month: 9, day: 3),
            birthPlace: "千葉県",
            notes: "旧姓: 田中。小学校教諭として30年勤務"
        )

        let sachiko = FamilyMember(
            firstName: "幸子",
            lastName: "鈴木",
            gender: .female,
            birthDate: makeDate(year: 1967, month: 12, day: 11),
            birthPlace: "東京都",
            notes: "旧姓: 山田。長女。総合病院の看護師長"
        )

        let kenta = FamilyMember(
            firstName: "健太",
            lastName: "鈴木",
            gender: .male,
            birthDate: makeDate(year: 1964, month: 1, day: 28),
            birthPlace: "埼玉県",
            notes: "幸子の夫。市役所の公務員"
        )

        // --- 第3世代（子） ---
        let shota = FamilyMember(
            firstName: "翔太",
            lastName: "山田",
            gender: .male,
            birthDate: makeDate(year: 1992, month: 8, day: 14),
            birthPlace: "東京都",
            notes: "一郎の長男。ITエンジニアとしてスタートアップで活躍"
        )

        let yumi = FamilyMember(
            firstName: "由美",
            lastName: "山田",
            gender: .female,
            birthDate: makeDate(year: 1994, month: 4, day: 25),
            birthPlace: "大阪府",
            notes: "旧姓: 高橋。UIデザイナー"
        )

        let sakura = FamilyMember(
            firstName: "さくら",
            lastName: "山田",
            gender: .female,
            birthDate: makeDate(year: 1995, month: 3, day: 3),
            birthPlace: "東京都",
            notes: "一郎の次女。大学病院の小児科医"
        )

        let daiki = FamilyMember(
            firstName: "大輝",
            lastName: "鈴木",
            gender: .male,
            birthDate: makeDate(year: 1993, month: 11, day: 7),
            birthPlace: "埼玉県",
            notes: "健太の長男。企業法務専門の弁護士"
        )

        let akari = FamilyMember(
            firstName: "あかり",
            lastName: "鈴木",
            gender: .female,
            birthDate: makeDate(year: 1996, month: 6, day: 19),
            birthPlace: "埼玉県",
            notes: "健太の長女。調剤薬局の薬剤師"
        )

        // --- 第4世代（孫） ---
        let haruto = FamilyMember(
            firstName: "陽翔",
            lastName: "山田",
            gender: .male,
            birthDate: makeDate(year: 2022, month: 1, day: 15),
            birthPlace: "東京都",
            notes: "翔太と由美の長男"
        )

        let yuna = FamilyMember(
            firstName: "結菜",
            lastName: "山田",
            gender: .female,
            birthDate: makeDate(year: 2024, month: 6, day: 30),
            birthPlace: "東京都",
            notes: "翔太と由美の長女"
        )

        // インデックス順で返す（親子関係設定時に参照しやすいように）
        return [
            taro,    // 0: 山田太郎
            hanako,  // 1: 山田花子
            ichiro,  // 2: 山田一郎
            misaki,  // 3: 山田美咲
            sachiko, // 4: 鈴木幸子
            kenta,   // 5: 鈴木健太
            shota,   // 6: 山田翔太
            yumi,    // 7: 山田由美
            sakura,  // 8: 山田さくら
            daiki,   // 9: 鈴木大輝
            akari,   // 10: 鈴木あかり
            haruto,  // 11: 山田陽翔
            yuna,    // 12: 山田結菜
        ]
    }

    /// 親子関係を設定（addChild は双方向リレーションを自動設定）
    private func setupParentChildRelationships(_ members: [FamilyMember]) {
        let taro = members[0]
        let hanako = members[1]
        let ichiro = members[2]
        let misaki = members[3]
        let sachiko = members[4]
        let kenta = members[5]
        let shota = members[6]
        let yumi = members[7]
        let sakura = members[8]
        let daiki = members[9]
        let akari = members[10]
        let haruto = members[11]
        let yuna = members[12]

        // 第1世代 → 第2世代
        taro.addChild(ichiro)
        hanako.addChild(ichiro)
        taro.addChild(sachiko)
        hanako.addChild(sachiko)

        // 第2世代 → 第3世代
        ichiro.addChild(shota)
        misaki.addChild(shota)
        ichiro.addChild(sakura)
        misaki.addChild(sakura)

        kenta.addChild(daiki)
        sachiko.addChild(daiki)
        kenta.addChild(akari)
        sachiko.addChild(akari)

        // 第3世代 → 第4世代
        shota.addChild(haruto)
        yumi.addChild(haruto)
        shota.addChild(yuna)
        yumi.addChild(yuna)
    }

    /// 婚姻関係を設定
    private func setupMarriages(_ members: [FamilyMember]) throws {
        let taro = members[0]
        let hanako = members[1]
        let ichiro = members[2]
        let misaki = members[3]
        let sachiko = members[4]
        let kenta = members[5]
        let shota = members[6]
        let yumi = members[7]

        // 山田太郎 × 山田花子（1960年）
        let marriage1 = Marriage(
            marriageDate: makeDate(year: 1960, month: 4, day: 10),
            marriagePlace: "東京都文京区"
        )
        modelContext.insert(marriage1)
        marriage1.setPartners(taro, hanako)

        // 山田一郎 × 山田美咲（1990年）
        let marriage2 = Marriage(
            marriageDate: makeDate(year: 1990, month: 6, day: 15),
            marriagePlace: "東京都港区"
        )
        modelContext.insert(marriage2)
        marriage2.setPartners(ichiro, misaki)

        // 鈴木健太 × 鈴木幸子（1992年）
        let marriage3 = Marriage(
            marriageDate: makeDate(year: 1992, month: 10, day: 20),
            marriagePlace: "埼玉県さいたま市"
        )
        modelContext.insert(marriage3)
        marriage3.setPartners(kenta, sachiko)

        // 山田翔太 × 山田由美（2020年）
        let marriage4 = Marriage(
            marriageDate: makeDate(year: 2020, month: 3, day: 21),
            marriagePlace: "京都府京都市"
        )
        modelContext.insert(marriage4)
        marriage4.setPartners(shota, yumi)
    }

    // MARK: - Helpers

    /// 日付生成ヘルパー
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.calendar = Calendar(identifier: .gregorian)
        return components.date ?? Date()
    }
}
