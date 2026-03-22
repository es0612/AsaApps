//
//  SampleDataGenerator.swift
//  AsaFitnessCoach
//
//  デモ動画撮影用のサンプルデータ投入
//

import Foundation

@MainActor
final class SampleDataGenerator {

    // MARK: - Properties

    private let dataService: DataService

    // MARK: - Initialization

    init(dataService: DataService) {
        self.dataService = dataService
    }

    // MARK: - Public

    func insertSampleData() {
        let profile = createUserProfile()
        dataService.saveUserProfile(profile)

        let plans = createWorkoutPlans()
        for plan in plans {
            dataService.saveWorkoutPlan(plan)
        }

        let sessions = createWorkoutSessions(plans: plans)
        for session in sessions {
            dataService.saveWorkoutSession(session)
        }
    }

    // MARK: - UserProfile

    private func createUserProfile() -> UserProfile {
        let profile = UserProfile(
            name: "朝活パパ",
            fitnessLevel: .intermediate,
            primaryGoal: .muscleGain,
            preferredWorkoutDuration: 30,
            workoutDaysPerWeek: 4
        )
        profile.height = 175.0
        profile.weight = 72.0
        profile.gender = .male
        profile.birthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1))
        profile.availableEquipment = [.dumbbells, .bench, .yogaMat, .pullUpBar]
        return profile
    }

    // MARK: - WorkoutPlans

    private func createWorkoutPlans() -> [WorkoutPlan] {
        [
            createUpperBodyPlan(),
            createLowerBodyPlan(),
            createHIITPlan(),
            createCorePlan(),
        ]
    }

    private func createUpperBodyPlan() -> WorkoutPlan {
        let plan = WorkoutPlan(
            name: "上半身の日",
            description: "胸・背中・腕を鍛える筋力トレーニング",
            difficulty: .intermediate,
            category: .strength
        )
        plan.isActive = true
        plan.targetMuscleGroups = [.pectoralisMajor, .latissimusDorsi, .biceps, .triceps]

        // 今日の曜日を必ず含める
        let today = WeekDay.today
        var days: Set<WeekDay> = [today]
        let allDays = WeekDay.allCases
        for day in allDays where day != today {
            if days.count < 3 { days.insert(day) }
        }
        plan.scheduledDays = Array(days)

        let exercises: [(String, Double?)] = [
            ("ベンチプレス", 60.0),
            ("ダンベルフライ", 12.0),
            ("ダンベルロウ", 20.0),
            ("懸垂", nil),
        ]
        for (name, weight) in exercises {
            if let exercise = exerciseFromPreset(name: name, weight: weight) {
                plan.addExercise(exercise)
            }
        }
        return plan
    }

    private func createLowerBodyPlan() -> WorkoutPlan {
        let plan = WorkoutPlan(
            name: "下半身の日",
            description: "脚全体を鍛える筋力トレーニング",
            difficulty: .intermediate,
            category: .strength
        )
        plan.isActive = true
        plan.targetMuscleGroups = [.quadriceps, .glutes, .hamstrings]

        let today = WeekDay.today
        let allDays = WeekDay.allCases
        let todayIndex = allDays.firstIndex(of: today) ?? 0
        let day2 = allDays[(todayIndex + 2) % allDays.count]
        let day3 = allDays[(todayIndex + 4) % allDays.count]
        plan.scheduledDays = [day2, day3]

        let exercises: [(String, Double?)] = [
            ("スクワット", 80.0),
            ("ランジ", nil),
            ("レッグプレス", 100.0),
        ]
        for (name, weight) in exercises {
            if let exercise = exerciseFromPreset(name: name, weight: weight) {
                plan.addExercise(exercise)
            }
        }
        return plan
    }

    private func createHIITPlan() -> WorkoutPlan {
        let plan = WorkoutPlan(
            name: "HIIT トレーニング",
            description: "全身を使った高強度インターバルトレーニング",
            difficulty: .intermediate,
            category: .hiit
        )
        plan.isActive = true
        plan.targetMuscleGroups = [.quadriceps, .rectusAbdominis, .deltoids]

        let today = WeekDay.today
        let allDays = WeekDay.allCases
        let todayIndex = allDays.firstIndex(of: today) ?? 0
        let day1 = allDays[(todayIndex + 1) % allDays.count]
        let day2 = allDays[(todayIndex + 3) % allDays.count]
        plan.scheduledDays = [day1, day2]

        for name in ["バーピー", "マウンテンクライマー", "ジャンピングジャック"] {
            if let exercise = exerciseFromPreset(name: name, weight: nil) {
                plan.addExercise(exercise)
            }
        }
        return plan
    }

    private func createCorePlan() -> WorkoutPlan {
        let plan = WorkoutPlan(
            name: "体幹・ストレッチ",
            description: "体幹強化と柔軟性向上のリカバリーメニュー",
            difficulty: .beginner,
            category: .yoga
        )
        plan.isActive = false
        plan.targetMuscleGroups = [.rectusAbdominis, .transverseAbdominis]

        let today = WeekDay.today
        let allDays = WeekDay.allCases
        let todayIndex = allDays.firstIndex(of: today) ?? 0
        let day = allDays[(todayIndex + 5) % allDays.count]
        plan.scheduledDays = [day]

        for name in ["プランク", "クランチ", "ダウンワードドッグ"] {
            if let exercise = exerciseFromPreset(name: name, weight: nil) {
                plan.addExercise(exercise)
            }
        }
        return plan
    }

    // MARK: - WorkoutSessions

    private func createWorkoutSessions(plans: [WorkoutPlan]) -> [WorkoutSession] {
        guard plans.count >= 4 else { return [] }
        let upperBody = plans[0]
        let lowerBody = plans[1]
        let hiit = plans[2]
        let core = plans[3]

        // 過去3週間にわたるセッション配置
        let sessionConfigs: [(plan: WorkoutPlan, daysAgo: Int, rating: SessionRating, rpe: Int, calories: Double)] = [
            (upperBody, 20, .good,      6, 280),
            (lowerBody, 18, .good,      7, 320),
            (hiit,      16, .okay,      8, 250),
            (upperBody, 13, .good,      6, 290),
            (lowerBody, 11, .excellent, 7, 330),
            (hiit,       9, .good,      7, 260),
            (upperBody,  6, .excellent, 6, 300),
            (lowerBody,  4, .good,      7, 340),
            (hiit,       2, .good,      8, 270),
            (core,       1, .excellent, 5, 150),
        ]

        // 上半身: ベンチプレスの重量進捗 (55 → 57.5 → 60)
        let benchWeights: [Double] = [55.0, 57.5, 60.0]
        // 下半身: スクワットの重量進捗 (70 → 75 → 80)
        let squatWeights: [Double] = [70.0, 75.0, 80.0]

        var upperIdx = 0
        var lowerIdx = 0

        return sessionConfigs.map { config in
            let session = createSession(
                plan: config.plan,
                daysAgo: config.daysAgo,
                durationMinutes: config.plan === core ? 25 : 35,
                rating: config.rating,
                rpe: config.rpe,
                calories: config.calories
            )

            if config.plan === upperBody {
                let benchWeight = benchWeights[min(upperIdx, benchWeights.count - 1)]
                addUpperBodyExercises(to: session, benchWeight: benchWeight, rowWeight: benchWeight < 58 ? 18.0 : 20.0)
                upperIdx += 1
            } else if config.plan === lowerBody {
                let squatWeight = squatWeights[min(lowerIdx, squatWeights.count - 1)]
                addLowerBodyExercises(to: session, squatWeight: squatWeight)
                lowerIdx += 1
            } else if config.plan === hiit {
                addHIITExercises(to: session)
            } else {
                addCoreExercises(to: session)
            }

            session.workoutPlan = config.plan
            return session
        }
    }

    private func createSession(
        plan: WorkoutPlan,
        daysAgo: Int,
        durationMinutes: Int,
        rating: SessionRating,
        rpe: Int,
        calories: Double
    ) -> WorkoutSession {
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        startComponents.hour = 6
        startComponents.minute = 0
        let todayAt6 = calendar.date(from: startComponents) ?? Date()
        let startTime = calendar.date(byAdding: .day, value: -daysAgo, to: todayAt6)!

        let session = WorkoutSession(planName: plan.name, startTime: startTime)
        session.planId = plan.id
        session.endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        session.isCompleted = true
        session.rating = rating
        session.perceivedExertion = rpe
        session.totalCalories = calories
        session.averageHeartRate = 125 + rpe * 3
        return session
    }

    // MARK: - CompletedExercise Builders

    private func addUpperBodyExercises(to session: WorkoutSession, benchWeight: Double, rowWeight: Double) {
        session.addCompletedExercise(completedExercise(
            name: "ベンチプレス", sets: 4, reps: 8, weight: benchWeight, form: .good
        ))
        session.addCompletedExercise(completedExercise(
            name: "ダンベルフライ", sets: 3, reps: 12, weight: 12.0, form: .good
        ))
        session.addCompletedExercise(completedExercise(
            name: "ダンベルロウ", sets: 3, reps: 10, weight: rowWeight, form: .good
        ))
        session.addCompletedExercise(completedExercise(
            name: "懸垂", sets: 3, reps: 8, weight: nil, form: .excellent
        ))
    }

    private func addLowerBodyExercises(to session: WorkoutSession, squatWeight: Double) {
        session.addCompletedExercise(completedExercise(
            name: "スクワット", sets: 4, reps: 8, weight: squatWeight, form: .good
        ))
        session.addCompletedExercise(completedExercise(
            name: "ランジ", sets: 3, reps: 12, weight: nil, form: .good
        ))
        session.addCompletedExercise(completedExercise(
            name: "レッグプレス", sets: 3, reps: 12, weight: squatWeight + 30, form: .excellent
        ))
    }

    private func addHIITExercises(to session: WorkoutSession) {
        session.addCompletedExercise(completedExercise(
            name: "バーピー", sets: 3, reps: 10, weight: nil, form: .good
        ))
        session.addCompletedExercise(completedExercise(
            name: "マウンテンクライマー", sets: 3, reps: 1, weight: nil, form: .good, duration: 45
        ))
        session.addCompletedExercise(completedExercise(
            name: "ジャンピングジャック", sets: 3, reps: 1, weight: nil, form: .excellent, duration: 60
        ))
    }

    private func addCoreExercises(to session: WorkoutSession) {
        session.addCompletedExercise(completedExercise(
            name: "プランク", sets: 3, reps: 1, weight: nil, form: .excellent, duration: 60
        ))
        session.addCompletedExercise(completedExercise(
            name: "クランチ", sets: 3, reps: 20, weight: nil, form: .good
        ))
        session.addCompletedExercise(completedExercise(
            name: "ダウンワードドッグ", sets: 2, reps: 1, weight: nil, form: .excellent, duration: 45
        ))
    }

    // MARK: - Helpers

    private func exerciseFromPreset(name: String, weight: Double?) -> Exercise? {
        guard let preset = PresetExercises.all.first(where: { $0.name == name }) else { return nil }
        let exercise = preset.toExercise()
        exercise.weight = weight
        return exercise
    }

    private func completedExercise(
        name: String,
        sets: Int,
        reps: Int,
        weight: Double?,
        form: FormQuality,
        duration: TimeInterval? = nil
    ) -> CompletedExercise {
        var exercise = CompletedExercise(
            exerciseId: UUID(),
            exerciseName: name,
            isCompleted: true
        )
        exercise.formQuality = form

        for setNumber in 1...sets {
            var record = SetRecord(setNumber: setNumber, isCompleted: true)
            record.reps = reps
            record.weight = weight
            record.duration = duration
            record.restTaken = 60
            exercise.actualSets.append(record)
        }

        return exercise
    }
}
