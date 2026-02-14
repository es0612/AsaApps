#if os(iOS)
import Foundation
import CoreMotion

// MARK: - ActivityRecognitionService

/// CoreMotion ラッパーサービス
///
/// 歩行・走行・自転車・車等のアクティビティを検出・記録する。
@MainActor
@Observable
public final class ActivityRecognitionService: ActivityRecognitionServiceProtocol {
    private let motionActivityManager: CMMotionActivityManager

    // MARK: - Init

    public init() {
        self.motionActivityManager = CMMotionActivityManager()
    }

    // MARK: - ActivityRecognitionServiceProtocol

    public func requestAuthorization() async -> Bool {
        guard CMMotionActivityManager.isActivityAvailable() else {
            return false
        }
        // CoreMotion は初回クエリ時に権限ダイアログが表示される
        // ダミークエリで権限をリクエスト
        return await withCheckedContinuation { continuation in
            let now = Date()
            let oneHourAgo = now.addingTimeInterval(-3600)
            motionActivityManager.queryActivityStarting(
                from: oneHourAgo,
                to: now,
                to: .main
            ) { _, error in
                continuation.resume(returning: error == nil)
            }
        }
    }

    public func startMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        motionActivityManager.startActivityUpdates(to: .main) { _ in
            // リアルタイム更新はUIで処理
        }
    }

    public func stopMonitoring() {
        motionActivityManager.stopActivityUpdates()
    }

    public func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [ActivityRecord] {
        guard CMMotionActivityManager.isActivityAvailable() else {
            throw LifeLogError.activityNotAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            motionActivityManager.queryActivityStarting(
                from: startDate,
                to: endDate,
                to: .main
            ) { activities, error in
                if let error {
                    continuation.resume(throwing: LifeLogError.saveFailed(underlying: error))
                    return
                }
                guard let activities else {
                    continuation.resume(returning: [])
                    return
                }

                var records: [ActivityRecord] = []
                for (index, activity) in activities.enumerated() {
                    let activityType = Self.mapActivityType(activity)
                    let activityEnd = index + 1 < activities.count
                        ? activities[index + 1].startDate
                        : endDate
                    records.append(ActivityRecord(
                        startDate: activity.startDate,
                        endDate: activityEnd,
                        activityType: activityType,
                        confidence: Self.mapConfidence(activity.confidence)
                    ))
                }
                continuation.resume(returning: records)
            }
        }
    }

    // MARK: - Private

    /// CMMotionActivity → ActivityType 変換
    private static func mapActivityType(_ activity: CMMotionActivity) -> ActivityType {
        if activity.running { return .running }
        if activity.cycling { return .cycling }
        if activity.automotive { return .driving }
        if activity.walking { return .walking }
        return .stationary
    }

    /// CMMotionActivityConfidence → Double 変換
    private static func mapConfidence(_ confidence: CMMotionActivityConfidence) -> Double {
        switch confidence {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 1.0
        @unknown default: return 0.0
        }
    }
}
#endif
