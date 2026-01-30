//
//  PresetExercises.swift
//  AsaFitnessCoach
//
//  プリセットエクササイズのデータ
//

import Foundation

// MARK: - PresetExercises

struct PresetExercises {
    // MARK: - 全エクササイズ

    static let all: [PresetExercise] = chestExercises + backExercises + legExercises +
        shoulderExercises + armExercises + coreExercises + cardioExercises + flexibilityExercises

    // MARK: - 胸のエクササイズ

    static let chestExercises: [PresetExercise] = [
        PresetExercise(
            name: "ベンチプレス",
            category: .chest,
            targetMuscles: [.pectoralisMajor, .triceps, .deltoids],
            requiredEquipment: [.barbell, .bench],
            defaultSets: 4,
            defaultReps: 8,
            defaultRestTime: 90,
            difficulty: .intermediate,
            instructions: "1. ベンチに仰向けになり、バーを肩幅より少し広く握る\n2. バーを胸の中央に下ろす\n3. 胸を張りながらバーを押し上げる"
        ),
        PresetExercise(
            name: "ダンベルフライ",
            category: .chest,
            targetMuscles: [.pectoralisMajor, .pectoralisMinor],
            requiredEquipment: [.dumbbells, .bench],
            defaultSets: 3,
            defaultReps: 12,
            defaultRestTime: 60,
            difficulty: .intermediate,
            instructions: "1. ダンベルを持ちベンチに仰向けになる\n2. 腕を広げながらダンベルを下ろす\n3. 胸の力で腕を閉じるようにダンベルを上げる"
        ),
        PresetExercise(
            name: "腕立て伏せ",
            category: .chest,
            targetMuscles: [.pectoralisMajor, .triceps, .deltoids],
            requiredEquipment: [.none],
            defaultSets: 3,
            defaultReps: 15,
            defaultRestTime: 60,
            difficulty: .beginner,
            instructions: "1. 手を肩幅より少し広く床につく\n2. 体を一直線に保ちながら肘を曲げて体を下ろす\n3. 胸と腕の力で体を押し上げる"
        ),
    ]

    // MARK: - 背中のエクササイズ

    static let backExercises: [PresetExercise] = [
        PresetExercise(
            name: "デッドリフト",
            category: .back,
            targetMuscles: [.latissimusDorsi, .erectorSpinae, .glutes, .hamstrings],
            requiredEquipment: [.barbell],
            defaultSets: 4,
            defaultReps: 6,
            defaultRestTime: 120,
            difficulty: .advanced,
            instructions: "1. バーの前に立ち、足を腰幅に開く\n2. 腰を落としてバーを握る\n3. 背中を真っ直ぐに保ちながら立ち上がる"
        ),
        PresetExercise(
            name: "懸垂",
            category: .back,
            targetMuscles: [.latissimusDorsi, .biceps, .trapezius],
            requiredEquipment: [.pullUpBar],
            defaultSets: 3,
            defaultReps: 8,
            defaultRestTime: 90,
            difficulty: .intermediate,
            instructions: "1. バーを肩幅より広く握る\n2. 肩甲骨を寄せながら体を引き上げる\n3. ゆっくりと体を下ろす"
        ),
        PresetExercise(
            name: "ダンベルロウ",
            category: .back,
            targetMuscles: [.latissimusDorsi, .rhomboids, .biceps],
            requiredEquipment: [.dumbbells, .bench],
            defaultSets: 3,
            defaultReps: 10,
            defaultRestTime: 60,
            difficulty: .intermediate,
            instructions: "1. ベンチに片膝と片手をつく\n2. もう片方の手でダンベルを持つ\n3. 肘を引き上げてダンベルを腰に近づける"
        ),
    ]

    // MARK: - 脚のエクササイズ

    static let legExercises: [PresetExercise] = [
        PresetExercise(
            name: "スクワット",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes, .hamstrings],
            requiredEquipment: [.barbell],
            defaultSets: 4,
            defaultReps: 8,
            defaultRestTime: 90,
            difficulty: .intermediate,
            instructions: "1. バーを肩に担ぎ、足を肩幅に開く\n2. 膝と股関節を曲げて腰を落とす\n3. 太ももが床と平行になるまで下げて立ち上がる"
        ),
        PresetExercise(
            name: "レッグプレス",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes],
            requiredEquipment: [.cableMachine],
            defaultSets: 3,
            defaultReps: 12,
            defaultRestTime: 60,
            difficulty: .beginner,
            instructions: "1. マシンに座り、足をプレートに置く\n2. 膝を曲げてウェイトを下ろす\n3. 足で押して膝を伸ばす"
        ),
        PresetExercise(
            name: "ランジ",
            category: .legs,
            targetMuscles: [.quadriceps, .glutes, .hamstrings],
            requiredEquipment: [.none],
            defaultSets: 3,
            defaultReps: 12,
            defaultRestTime: 60,
            difficulty: .beginner,
            instructions: "1. 足を腰幅に開いて立つ\n2. 片足を前に踏み出し膝を曲げる\n3. 後ろ足の膝が床に近づくまで下げる"
        ),
    ]

    // MARK: - 肩のエクササイズ

    static let shoulderExercises: [PresetExercise] = [
        PresetExercise(
            name: "ショルダープレス",
            category: .shoulders,
            targetMuscles: [.deltoids, .triceps],
            requiredEquipment: [.dumbbells],
            defaultSets: 3,
            defaultReps: 10,
            defaultRestTime: 60,
            difficulty: .intermediate,
            instructions: "1. ダンベルを肩の高さに持つ\n2. 腕を真っ直ぐ上に押し上げる\n3. ゆっくりと肩の高さに戻す"
        ),
        PresetExercise(
            name: "サイドレイズ",
            category: .shoulders,
            targetMuscles: [.deltoids],
            requiredEquipment: [.dumbbells],
            defaultSets: 3,
            defaultReps: 12,
            defaultRestTime: 45,
            difficulty: .beginner,
            instructions: "1. ダンベルを体の横に持つ\n2. 腕を真横に上げて肩の高さまで持ち上げる\n3. ゆっくりと下ろす"
        ),
    ]

    // MARK: - 腕のエクササイズ

    static let armExercises: [PresetExercise] = [
        PresetExercise(
            name: "バイセップカール",
            category: .arms,
            targetMuscles: [.biceps],
            requiredEquipment: [.dumbbells],
            defaultSets: 3,
            defaultReps: 12,
            defaultRestTime: 45,
            difficulty: .beginner,
            instructions: "1. ダンベルを体の横に持つ\n2. 肘を固定して前腕を持ち上げる\n3. ゆっくりと下ろす"
        ),
        PresetExercise(
            name: "トライセップスディップ",
            category: .arms,
            targetMuscles: [.triceps],
            requiredEquipment: [.bench],
            defaultSets: 3,
            defaultReps: 10,
            defaultRestTime: 60,
            difficulty: .beginner,
            instructions: "1. ベンチに手をつき、足を前に伸ばす\n2. 肘を曲げて体を下ろす\n3. 腕の力で体を押し上げる"
        ),
    ]

    // MARK: - 体幹のエクササイズ

    static let coreExercises: [PresetExercise] = [
        PresetExercise(
            name: "プランク",
            category: .core,
            targetMuscles: [.rectusAbdominis, .transverseAbdominis, .erectorSpinae],
            requiredEquipment: [.yogaMat],
            defaultSets: 3,
            defaultReps: 1,
            defaultDuration: 60,
            defaultRestTime: 45,
            difficulty: .beginner,
            instructions: "1. 前腕とつま先で体を支える\n2. 体を一直線に保つ\n3. お腹に力を入れて姿勢を維持する"
        ),
        PresetExercise(
            name: "クランチ",
            category: .core,
            targetMuscles: [.rectusAbdominis],
            requiredEquipment: [.yogaMat],
            defaultSets: 3,
            defaultReps: 20,
            defaultRestTime: 45,
            difficulty: .beginner,
            instructions: "1. 仰向けに寝て膝を曲げる\n2. 手を頭の後ろに置く\n3. 肩甲骨が床から離れるまで上体を起こす"
        ),
        PresetExercise(
            name: "ロシアンツイスト",
            category: .core,
            targetMuscles: [.obliques, .rectusAbdominis],
            requiredEquipment: [.yogaMat],
            defaultSets: 3,
            defaultReps: 20,
            defaultRestTime: 45,
            difficulty: .intermediate,
            instructions: "1. 座って膝を曲げ、足を床から浮かせる\n2. 上体を後ろに傾ける\n3. 左右に体を回転させる"
        ),
    ]

    // MARK: - 有酸素エクササイズ

    static let cardioExercises: [PresetExercise] = [
        PresetExercise(
            name: "ジャンピングジャック",
            category: .cardio,
            targetMuscles: [.quadriceps, .calves, .deltoids],
            requiredEquipment: [.none],
            defaultSets: 3,
            defaultReps: 1,
            defaultDuration: 60,
            defaultRestTime: 30,
            difficulty: .beginner,
            instructions: "1. 足を揃えて立つ\n2. ジャンプしながら足を開き、腕を上げる\n3. ジャンプして元の姿勢に戻る"
        ),
        PresetExercise(
            name: "バーピー",
            category: .cardio,
            targetMuscles: [.quadriceps, .pectoralisMajor, .rectusAbdominis],
            requiredEquipment: [.none],
            defaultSets: 3,
            defaultReps: 10,
            defaultRestTime: 60,
            difficulty: .intermediate,
            instructions: "1. 立った状態からしゃがむ\n2. 手を床につけて足を後ろに伸ばす\n3. 腕立て伏せをして足を戻し、ジャンプする"
        ),
        PresetExercise(
            name: "マウンテンクライマー",
            category: .cardio,
            targetMuscles: [.rectusAbdominis, .quadriceps, .deltoids],
            requiredEquipment: [.none],
            defaultSets: 3,
            defaultReps: 1,
            defaultDuration: 45,
            defaultRestTime: 30,
            difficulty: .intermediate,
            instructions: "1. プランクの姿勢になる\n2. 交互に膝を胸に引き寄せる\n3. できるだけ速く動く"
        ),
    ]

    // MARK: - 柔軟性エクササイズ

    static let flexibilityExercises: [PresetExercise] = [
        PresetExercise(
            name: "ハムストリングストレッチ",
            category: .flexibility,
            targetMuscles: [.hamstrings],
            requiredEquipment: [.yogaMat],
            defaultSets: 2,
            defaultReps: 1,
            defaultDuration: 30,
            defaultRestTime: 15,
            difficulty: .beginner,
            instructions: "1. 床に座って片足を伸ばす\n2. 上体を前に倒して足先に手を伸ばす\n3. 30秒間姿勢を維持する"
        ),
        PresetExercise(
            name: "ダウンワードドッグ",
            category: .flexibility,
            targetMuscles: [.hamstrings, .calves, .latissimusDorsi],
            requiredEquipment: [.yogaMat],
            defaultSets: 2,
            defaultReps: 1,
            defaultDuration: 45,
            defaultRestTime: 15,
            difficulty: .beginner,
            instructions: "1. 四つん這いになる\n2. 膝を伸ばしてお尻を天井に向ける\n3. かかとを床に近づけながら姿勢を維持する"
        ),
    ]

    // MARK: - カテゴリ別取得

    static func exercises(for category: ExerciseCategory) -> [PresetExercise] {
        switch category {
        case .chest: return chestExercises
        case .back: return backExercises
        case .legs: return legExercises
        case .shoulders: return shoulderExercises
        case .arms: return armExercises
        case .core: return coreExercises
        case .cardio: return cardioExercises
        case .flexibility: return flexibilityExercises
        default: return all
        }
    }

    // MARK: - 器具別取得

    static func exercises(with equipment: [Equipment]) -> [PresetExercise] {
        if equipment.isEmpty || equipment.contains(.none) {
            return all.filter { $0.requiredEquipment.isEmpty || $0.requiredEquipment == [.none] }
        }
        return all.filter { preset in
            preset.requiredEquipment.isEmpty ||
            preset.requiredEquipment.allSatisfy { equipment.contains($0) || $0 == .none }
        }
    }

    // MARK: - 難易度別取得

    static func exercises(for difficulty: ExerciseDifficulty) -> [PresetExercise] {
        all.filter { $0.difficulty.numericValue <= difficulty.numericValue }
    }
}

// MARK: - PresetExercise

struct PresetExercise: Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: ExerciseCategory
    var targetMuscles: [MuscleGroup]
    var requiredEquipment: [Equipment]
    var defaultSets: Int
    var defaultReps: Int
    var defaultDuration: TimeInterval?
    var defaultRestTime: TimeInterval
    var difficulty: ExerciseDifficulty
    var instructions: String

    /// Exercise モデルに変換
    func toExercise() -> Exercise {
        let exercise = Exercise(
            name: name,
            category: category,
            sets: defaultSets,
            reps: defaultReps,
            restTime: defaultRestTime
        )
        exercise.targetMuscles = targetMuscles
        exercise.requiredEquipment = requiredEquipment
        exercise.duration = defaultDuration
        exercise.difficulty = difficulty
        exercise.instructions = instructions
        return exercise
    }
}
