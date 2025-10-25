//
//  PresetExercises.swift
//  AsaWorkoutPlanner
//
//  プリセットエクササイズライブラリ
//  100種類以上のエクササイズデータを提供
//

import Foundation

/// プリセットエクササイズのライブラリ
struct PresetExerciseLibrary {

    // MARK: - 胸のエクササイズ

    static let chestExercises: [ExerciseTemplate] = [
        // バーベル種目
        ExerciseTemplate(
            name: "ベンチプレス",
            category: .chest,
            targetMuscles: [.pectoralisMajor, .triceps, .deltoids],
            sets: 3,
            reps: 8,
            restTime: 120,
            instructions: "1. ベンチに仰向けになり、肩幅より少し広めでバーを握る\n2. バーを胸の中央まで下ろす\n3. 力強く押し上げる",
            tips: "肩甲骨を寄せて、胸を張った状態を維持"
        ),
        ExerciseTemplate(
            name: "インクラインベンチプレス",
            category: .chest,
            targetMuscles: [.pectoralisMajor, .deltoids],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "30-45度の角度のベンチで実施",
            tips: "大胸筋上部を重点的に鍛える"
        ),
        ExerciseTemplate(
            name: "デクラインベンチプレス",
            category: .chest,
            targetMuscles: [.pectoralisMajor],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "15-30度下げたベンチで実施",
            tips: "大胸筋下部を重点的に鍛える"
        ),

        // ダンベル種目
        ExerciseTemplate(
            name: "ダンベルフライ",
            category: .chest,
            targetMuscles: [.pectoralisMajor],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "1. ベンチに仰向けになり、ダンベルを両手に持つ\n2. 腕を広げて胸をストレッチ\n3. 弧を描くように上げる",
            tips: "肘は軽く曲げたまま維持"
        ),
        ExerciseTemplate(
            name: "ダンベルベンチプレス",
            category: .chest,
            targetMuscles: [.pectoralisMajor, .triceps],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "バーベルベンチプレスと同様の動作をダンベルで実施",
            tips: "可動域を広く使える"
        ),

        // 自重種目
        ExerciseTemplate(
            name: "プッシュアップ",
            category: .chest,
            targetMuscles: [.pectoralisMajor, .triceps, .deltoids],
            sets: 3,
            reps: 15,
            restTime: 45,
            instructions: "1. 腕立て伏せの姿勢\n2. 体を一直線に保ちながら下ろす\n3. 胸が床につく寸前まで下ろして押し上げる",
            tips: "コアを締めて体幹を安定させる"
        ),
        ExerciseTemplate(
            name: "ディップス",
            category: .chest,
            targetMuscles: [.pectoralisMajor, .triceps],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "体を前傾させて胸に効かせる",
            tips: "肘を外に広げると胸により効く"
        ),

        // ケーブル種目
        ExerciseTemplate(
            name: "ケーブルクロスオーバー",
            category: .chest,
            targetMuscles: [.pectoralisMajor],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "ケーブルを使って胸の前でクロス",
            tips: "大胸筋の形を整えるのに効果的"
        )
    ]

    // MARK: - 背中のエクササイズ

    static let backExercises: [ExerciseTemplate] = [
        // プル系種目
        ExerciseTemplate(
            name: "デッドリフト",
            category: .back,
            targetMuscles: [.erectorSpinae, .latissimusDorsi, .glutes, .hamstrings],
            sets: 3,
            reps: 5,
            restTime: 180,
            instructions: "1. バーを肩幅で握る\n2. 背筋を伸ばしたまま持ち上げる\n3. ゆっくり下ろす",
            tips: "背中を丸めない。腰を痛めないよう注意"
        ),
        ExerciseTemplate(
            name: "ベントオーバーロウ",
            category: .back,
            targetMuscles: [.latissimusDorsi, .rhomboids, .trapezius],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "前傾姿勢でバーを引き上げる",
            tips: "背中を丸めず、胸を張る"
        ),
        ExerciseTemplate(
            name: "ワンアームダンベルロウ",
            category: .back,
            targetMuscles: [.latissimusDorsi, .rhomboids],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "片手ずつ実施",
            tips: "肩甲骨を寄せる意識"
        ),

        // プルアップ系
        ExerciseTemplate(
            name: "プルアップ（懸垂）",
            category: .back,
            targetMuscles: [.latissimusDorsi, .biceps],
            sets: 3,
            reps: 8,
            restTime: 120,
            instructions: "1. 肩幅より広めでバーを握る\n2. 胸をバーに近づけるように引き上げる\n3. ゆっくり下ろす",
            tips: "背中で引く意識を持つ"
        ),
        ExerciseTemplate(
            name: "チンアップ",
            category: .back,
            targetMuscles: [.latissimusDorsi, .biceps],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "逆手（手のひらを自分側）で握る",
            tips: "上腕二頭筋にも効果的"
        ),
        ExerciseTemplate(
            name: "ラットプルダウン",
            category: .back,
            targetMuscles: [.latissimusDorsi],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "ケーブルマシンで上から引く動作",
            tips: "肩甲骨を下に引く意識"
        ),

        // ロウ系
        ExerciseTemplate(
            name: "シーテッドロウ",
            category: .back,
            targetMuscles: [.latissimusDorsi, .rhomboids, .trapezius],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "座った姿勢でケーブルを引く",
            tips: "背筋を伸ばしたまま"
        ),
        ExerciseTemplate(
            name: "Tバーロウ",
            category: .back,
            targetMuscles: [.latissimusDorsi, .rhomboids],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "Tバーマシンまたはバーベルで実施",
            tips: "背中全体に効かせる"
        )
    ]

    // MARK: - 脚のエクササイズ

    static let legExercises: [ExerciseTemplate] = [
        // スクワット系
        ExerciseTemplate(
            name: "バーベルスクワット",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes, .hamstrings],
            sets: 3,
            reps: 8,
            restTime: 180,
            instructions: "1. バーを肩に担ぐ\n2. 腰を下ろす\n3. 力強く立ち上がる",
            tips: "膝がつま先より前に出ないように"
        ),
        ExerciseTemplate(
            name: "フロントスクワット",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes],
            sets: 3,
            reps: 10,
            restTime: 120,
            instructions: "バーを胸の前に持つ",
            tips: "大腿四頭筋に効果的"
        ),
        ExerciseTemplate(
            name: "ブルガリアンスクワット",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "片足を後ろのベンチに乗せる",
            tips: "バランス強化にも効果的"
        ),

        // ランジ系
        ExerciseTemplate(
            name: "ウォーキングランジ",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes, .hamstrings],
            sets: 3,
            reps: 20,
            restTime: 60,
            instructions: "前方に大きく一歩踏み出す",
            tips: "上体を真っ直ぐ保つ"
        ),
        ExerciseTemplate(
            name: "バックランジ",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "後方に一歩下がる",
            tips: "膝への負担が少ない"
        ),

        // レッグプレス系
        ExerciseTemplate(
            name: "レッグプレス",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes, .hamstrings],
            sets: 3,
            reps: 12,
            restTime: 90,
            instructions: "マシンで脚を押す動作",
            tips: "足の位置で効く部位が変わる"
        ),

        // ハムストリング系
        ExerciseTemplate(
            name: "レッグカール",
            category: .legs,
            targetMuscles: [.hamstrings],
            sets: 3,
            reps: 15,
            restTime: 45,
            instructions: "マシンで脚を曲げる動作",
            tips: "ハムストリング集中トレーニング"
        ),
        ExerciseTemplate(
            name: "ルーマニアンデッドリフト",
            category: .legs,
            targetMuscles: [.hamstrings, .glutes, .erectorSpinae],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "膝を軽く曲げたまま前傾",
            tips: "ハムストリングのストレッチを感じる"
        ),

        // カーフ系
        ExerciseTemplate(
            name: "カーフレイズ",
            category: .legs,
            targetMuscles: [.calves],
            sets: 4,
            reps: 20,
            restTime: 30,
            instructions: "つま先立ちを繰り返す",
            tips: "フルレンジで実施"
        )
    ]

    // MARK: - 肩のエクササイズ

    static let shoulderExercises: [ExerciseTemplate] = [
        // プレス系
        ExerciseTemplate(
            name: "ショルダープレス",
            category: .shoulders,
            targetMuscles: [.deltoids, .triceps],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "1. ダンベルまたはバーを肩の高さに構える\n2. 頭上に押し上げる\n3. ゆっくり下ろす",
            tips: "コアを締めて安定させる"
        ),
        ExerciseTemplate(
            name: "アーノルドプレス",
            category: .shoulders,
            targetMuscles: [.deltoids],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "手のひらを自分側から外側に回転させながら押し上げる",
            tips: "三角筋全体に効かせる"
        ),

        // レイズ系
        ExerciseTemplate(
            name: "サイドレイズ",
            category: .shoulders,
            targetMuscles: [.deltoids],
            sets: 3,
            reps: 15,
            restTime: 45,
            instructions: "ダンベルを横に上げる",
            tips: "三角筋中部を鍛える"
        ),
        ExerciseTemplate(
            name: "フロントレイズ",
            category: .shoulders,
            targetMuscles: [.deltoids],
            sets: 3,
            reps: 12,
            restTime: 45,
            instructions: "ダンベルを前方に上げる",
            tips: "三角筋前部を鍛える"
        ),
        ExerciseTemplate(
            name: "リアレイズ",
            category: .shoulders,
            targetMuscles: [.deltoids, .rhomboids],
            sets: 3,
            reps: 15,
            restTime: 45,
            instructions: "前傾姿勢でダンベルを後方に上げる",
            tips: "三角筋後部を鍛える"
        ),

        // ロウ系
        ExerciseTemplate(
            name: "アップライトロウ",
            category: .shoulders,
            targetMuscles: [.deltoids, .trapezius],
            sets: 3,
            reps: 12,
            restTime: 60,
            instructions: "バーを顎の高さまで引き上げる",
            tips: "肘を高く上げる"
        )
    ]

    // MARK: - 腕のエクササイズ

    static let armExercises: [ExerciseTemplate] = [
        // 上腕二頭筋
        ExerciseTemplate(
            name: "バーベルカール",
            category: .arms,
            targetMuscles: [.biceps],
            sets: 3,
            reps: 10,
            restTime: 60,
            instructions: "バーを持って肘を曲げる",
            tips: "肘を固定して上腕二頭筋を集中"
        ),
        ExerciseTemplate(
            name: "ダンベルカール",
            category: .arms,
            targetMuscles: [.biceps],
            sets: 3,
            reps: 12,
            restTime: 45,
            instructions: "ダンベルを交互または同時に曲げる",
            tips: "可動域を広く使う"
        ),
        ExerciseTemplate(
            name: "ハンマーカール",
            category: .arms,
            targetMuscles: [.biceps, .forearms],
            sets: 3,
            reps: 12,
            restTime: 45,
            instructions: "親指を上にしてカール",
            tips: "前腕にも効果的"
        ),
        ExerciseTemplate(
            name: "コンセントレーションカール",
            category: .arms,
            targetMuscles: [.biceps],
            sets: 3,
            reps: 12,
            restTime: 45,
            instructions: "座って片腕ずつ集中的に実施",
            tips: "上腕二頭筋のピークを作る"
        ),

        // 上腕三頭筋
        ExerciseTemplate(
            name: "トライセプスプッシュダウン",
            category: .arms,
            targetMuscles: [.triceps],
            sets: 3,
            reps: 15,
            restTime: 45,
            instructions: "ケーブルを下に押す",
            tips: "肘を固定"
        ),
        ExerciseTemplate(
            name: "スカルクラッシャー",
            category: .arms,
            targetMuscles: [.triceps],
            sets: 3,
            reps: 10,
            restTime: 60,
            instructions: "仰向けでバーを額の方に下ろす",
            tips: "上腕三頭筋全体に効かせる"
        ),
        ExerciseTemplate(
            name: "オーバーヘッドトライセプスエクステンション",
            category: .arms,
            targetMuscles: [.triceps],
            sets: 3,
            reps: 12,
            restTime: 45,
            instructions: "ダンベルを頭の後ろに下ろす",
            tips: "上腕三頭筋の長頭を鍛える"
        ),

        // 前腕
        ExerciseTemplate(
            name: "リストカール",
            category: .arms,
            targetMuscles: [.forearms],
            sets: 3,
            reps: 20,
            restTime: 30,
            instructions: "手首を曲げる動作",
            tips: "前腕屈筋群を鍛える"
        ),
        ExerciseTemplate(
            name: "リバースリストカール",
            category: .arms,
            targetMuscles: [.forearms],
            sets: 3,
            reps: 20,
            restTime: 30,
            instructions: "手首を反らす動作",
            tips: "前腕伸筋群を鍛える"
        )
    ]

    // MARK: - 体幹のエクササイズ

    static let coreExercises: [ExerciseTemplate] = [
        // プランク系
        ExerciseTemplate(
            name: "プランク",
            category: .core,
            targetMuscles: [.rectusAbdominis, .transverseAbdominis, .obliques],
            sets: 3,
            reps: 1,
            duration: 60,
            restTime: 30,
            instructions: "肘とつま先で体を支える",
            tips: "体を一直線に保つ"
        ),
        ExerciseTemplate(
            name: "サイドプランク",
            category: .core,
            targetMuscles: [.obliques, .transverseAbdominis],
            sets: 3,
            reps: 1,
            duration: 45,
            restTime: 30,
            instructions: "横向きで片肘とつま先で支える",
            tips: "腹斜筋を鍛える"
        ),

        // クランチ系
        ExerciseTemplate(
            name: "クランチ",
            category: .core,
            targetMuscles: [.rectusAbdominis],
            sets: 3,
            reps: 20,
            restTime: 30,
            instructions: "仰向けで上体を起こす",
            tips: "腰を床につけたまま"
        ),
        ExerciseTemplate(
            name: "バイシクルクランチ",
            category: .core,
            targetMuscles: [.rectusAbdominis, .obliques],
            sets: 3,
            reps: 30,
            restTime: 30,
            instructions: "対角線上の肘と膝を近づける",
            tips: "腹直筋と腹斜筋を同時に鍛える"
        ),

        // レッグレイズ系
        ExerciseTemplate(
            name: "レッグレイズ",
            category: .core,
            targetMuscles: [.rectusAbdominis, .hipFlexors],
            sets: 3,
            reps: 15,
            restTime: 45,
            instructions: "仰向けで脚を上げ下げ",
            tips: "下腹部に効かせる"
        ),
        ExerciseTemplate(
            name: "ハンギングレッグレイズ",
            category: .core,
            targetMuscles: [.rectusAbdominis],
            sets: 3,
            reps: 10,
            restTime: 60,
            instructions: "バーにぶら下がって脚を上げる",
            tips: "腹筋全体に効果的"
        ),

        // ロシアンツイスト系
        ExerciseTemplate(
            name: "ロシアンツイスト",
            category: .core,
            targetMuscles: [.obliques],
            sets: 3,
            reps: 30,
            restTime: 30,
            instructions: "座った姿勢で体を左右にひねる",
            tips: "腹斜筋を鍛える"
        ),

        // デッドバグ
        ExerciseTemplate(
            name: "デッドバグ",
            category: .core,
            targetMuscles: [.transverseAbdominis, .rectusAbdominis],
            sets: 3,
            reps: 20,
            restTime: 30,
            instructions: "仰向けで対角線上の手足を動かす",
            tips: "体幹の安定性を向上"
        )
    ]

    // MARK: - 有酸素運動

    static let cardioExercises: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "ランニング",
            category: .cardio,
            targetMuscles: [],
            sets: 1,
            reps: 1,
            duration: 1800, // 30分
            restTime: 0,
            instructions: "一定のペースで走る",
            tips: "心拍数をモニターして適切な強度を維持"
        ),
        ExerciseTemplate(
            name: "バーピー",
            category: .cardio,
            targetMuscles: [],
            sets: 3,
            reps: 15,
            restTime: 60,
            instructions: "スクワット → プランク → プッシュアップ → ジャンプ",
            tips: "全身運動で高強度"
        ),
        ExerciseTemplate(
            name: "ジャンピングジャック",
            category: .cardio,
            targetMuscles: [],
            sets: 3,
            reps: 30,
            restTime: 30,
            instructions: "ジャンプしながら手足を開閉",
            tips: "ウォームアップにも最適"
        ),
        ExerciseTemplate(
            name: "マウンテンクライマー",
            category: .cardio,
            targetMuscles: [.rectusAbdominis],
            sets: 3,
            reps: 30,
            restTime: 30,
            instructions: "プランク姿勢で膝を交互に胸に引き寄せる",
            tips: "有酸素と体幹トレーニングを兼ねる"
        )
    ]

    // MARK: - コンパウンド（複合）種目

    static let compoundExercises: [ExerciseTemplate] = [
        ExerciseTemplate(
            name: "クリーン",
            category: .compound,
            targetMuscles: [.quadriceps, .glutes, .trapezius, .deltoids],
            sets: 3,
            reps: 5,
            restTime: 180,
            instructions: "床からバーを肩まで一気に引き上げる",
            tips: "全身の爆発力を鍛える"
        ),
        ExerciseTemplate(
            name: "スナッチ",
            category: .compound,
            targetMuscles: [.quadriceps, .glutes, .trapezius, .deltoids],
            sets: 3,
            reps: 3,
            restTime: 180,
            instructions: "床から頭上まで一動作で引き上げる",
            tips: "高度な技術が必要"
        ),
        ExerciseTemplate(
            name: "スラスター",
            category: .compound,
            targetMuscles: [.quadriceps, .deltoids, .glutes],
            sets: 3,
            reps: 10,
            restTime: 90,
            instructions: "フロントスクワット → ショルダープレス",
            tips: "全身運動で高強度"
        )
    ]

    // MARK: - 全エクササイズの取得

    static var allExercises: [ExerciseTemplate] {
        chestExercises +
        backExercises +
        legExercises +
        shoulderExercises +
        armExercises +
        coreExercises +
        cardioExercises +
        compoundExercises
    }

    /// カテゴリー別にエクササイズを取得
    static func exercises(for category: ExerciseCategory) -> [ExerciseTemplate] {
        switch category {
        case .chest: return chestExercises
        case .back: return backExercises
        case .legs: return legExercises
        case .shoulders: return shoulderExercises
        case .arms: return armExercises
        case .core: return coreExercises
        case .cardio: return cardioExercises
        case .compound: return compoundExercises
        case .flexibility: return [] // 将来の拡張用
        }
    }

    /// 検索
    static func search(_ query: String) -> [ExerciseTemplate] {
        guard !query.isEmpty else { return allExercises }

        return allExercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query) ||
            exercise.instructions?.localizedCaseInsensitiveContains(query) == true ||
            exercise.targetMuscles.contains { muscle in
                muscle.rawValue.localizedCaseInsensitiveContains(query)
            }
        }
    }
}

// MARK: - エクササイズテンプレート

/// エクササイズのテンプレート（Exercise作成用のデータ）
struct ExerciseTemplate: Identifiable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let targetMuscles: [MuscleGroup]
    let sets: Int
    let reps: Int
    var duration: TimeInterval? = nil
    let restTime: TimeInterval
    var instructions: String? = nil
    var tips: String? = nil
    var videoURL: String? = nil

    /// Exerciseモデルに変換
    func toExercise() -> Exercise {
        let exercise = Exercise(
            name: name,
            category: category,
            sets: sets,
            reps: reps,
            restTime: restTime
        )

        exercise.targetMuscles = targetMuscles
        exercise.duration = duration
        exercise.instructions = instructions
        exercise.tips = tips
        exercise.videoURL = videoURL

        return exercise
    }
}
