//
//  WorkoutViewModel.swift
//  AsaFitnessCoach
//
//  ワークアウト実行ViewModel
//

import Foundation
import Combine

@Observable
@MainActor
final class WorkoutViewModel {
    // MARK: - Properties

    // セッション
    var session: WorkoutSession
    var plan: WorkoutPlan

    // 現在の状態
    var currentExerciseIndex: Int = 0
    var currentSetIndex: Int = 0
    var isResting: Bool = false
    var isPaused: Bool = false
    var isCompleted: Bool = false

    // タイマー
    var elapsedTime: TimeInterval = 0
    var restTimeRemaining: TimeInterval = 0

    private var timer: AnyCancellable?
    private var restTimer: AnyCancellable?

    // MARK: - Computed Properties

    var currentExercise: CompletedExercise? {
        guard currentExerciseIndex < session.completedExercises.count else { return nil }
        return session.completedExercises[currentExerciseIndex]
    }

    var currentPlanExercise: Exercise? {
        guard currentExerciseIndex < plan.exercises.count else { return nil }
        let sorted = plan.exercises.sorted { $0.order < $1.order }
        return sorted[currentExerciseIndex]
    }

    var currentSet: SetRecord? {
        guard let exercise = currentExercise,
              currentSetIndex < exercise.actualSets.count else { return nil }
        return exercise.actualSets[currentSetIndex]
    }

    var totalExercises: Int {
        session.completedExercises.count
    }

    var totalSets: Int {
        session.completedExercises.reduce(0) { $0 + $1.actualSets.count }
    }

    var completedSets: Int {
        session.completedExercises.reduce(0) { total, exercise in
            total + exercise.actualSets.filter { $0.isCompleted }.count
        }
    }

    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }

    var elapsedTimeString: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var restTimeRemainingString: String {
        let minutes = Int(restTimeRemaining) / 60
        let seconds = Int(restTimeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Initialization

    init(session: WorkoutSession, plan: WorkoutPlan) {
        self.session = session
        self.plan = plan
    }

    // MARK: - Timer Controls

    func startWorkout() {
        startMainTimer()
    }

    func pauseWorkout() {
        isPaused = true
        stopTimers()
    }

    func resumeWorkout() {
        isPaused = false
        startMainTimer()
        if isResting {
            startRestTimer()
        }
    }

    func finishWorkout() {
        stopTimers()
        session.complete()
        isCompleted = true
    }

    private func startMainTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isPaused else { return }
                self.elapsedTime += 1
            }
    }

    private func stopTimers() {
        timer?.cancel()
        timer = nil
        restTimer?.cancel()
        restTimer = nil
    }

    // MARK: - Set Completion

    func completeSet(reps: Int, weight: Double?) {
        guard currentExerciseIndex < session.completedExercises.count,
              currentSetIndex < session.completedExercises[currentExerciseIndex].actualSets.count else {
            return
        }

        // セットを完了としてマーク
        session.completedExercises[currentExerciseIndex].actualSets[currentSetIndex].isCompleted = true
        session.completedExercises[currentExerciseIndex].actualSets[currentSetIndex].reps = reps
        session.completedExercises[currentExerciseIndex].actualSets[currentSetIndex].weight = weight

        // 次のセットに移動
        moveToNextSet()
    }

    func skipSet() {
        moveToNextSet()
    }

    private func moveToNextSet() {
        guard let exercise = currentExercise else { return }

        if currentSetIndex < exercise.actualSets.count - 1 {
            // 次のセットへ（休憩開始）
            currentSetIndex += 1
            startRestPeriod()
        } else {
            // エクササイズ完了
            session.completedExercises[currentExerciseIndex].isCompleted = true
            moveToNextExercise()
        }
    }

    private func moveToNextExercise() {
        if currentExerciseIndex < session.completedExercises.count - 1 {
            currentExerciseIndex += 1
            currentSetIndex = 0
            // エクササイズ間も休憩
            startRestPeriod()
        } else {
            // ワークアウト完了
            finishWorkout()
        }
    }

    // MARK: - Rest Timer

    private func startRestPeriod() {
        guard let planExercise = currentPlanExercise else { return }

        isResting = true
        restTimeRemaining = planExercise.restTime
        startRestTimer()
    }

    private func startRestTimer() {
        restTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isPaused else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.endRestPeriod()
                }
            }
    }

    func skipRest() {
        endRestPeriod()
    }

    private func endRestPeriod() {
        isResting = false
        restTimeRemaining = 0
        restTimer?.cancel()
        restTimer = nil
    }

    // MARK: - Form Quality

    func setFormQuality(_ quality: FormQuality) {
        guard currentExerciseIndex < session.completedExercises.count else { return }
        session.completedExercises[currentExerciseIndex].formQuality = quality
    }

    // MARK: - Session Rating

    func setSessionRating(_ rating: SessionRating) {
        session.rating = rating
    }

    func setPerceivedExertion(_ rpe: Int) {
        session.perceivedExertion = rpe
    }

    func setNotes(_ notes: String) {
        session.notes = notes
    }
}
