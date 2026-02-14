import Foundation
import CoreMotion
import AsaLifeLogKit

// MARK: - AppMotionBridge

/// CoreMotion と AsaLifeLogKit の橋渡しサービス
@MainActor
@Observable
final class AppMotionBridge: ActivityRecognitionServiceProtocol {
    private let activityManager = CMMotionActivityManager()

    func requestAuthorization() async -> Bool {
        // CMMotionActivityManager は初回クエリ時に自動で権限リクエストされる
        return CMMotionActivityManager.isActivityAvailable()
    }

    func startMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { _ in
            // アクティビティ更新を受信
        }
    }

    func stopMonitoring() {
        activityManager.stopActivityUpdates()
    }

    func fetchActivities(from startDate: Date, to endDate: Date) async throws -> [ActivityRecord] {
        guard CMMotionActivityManager.isActivityAvailable() else {
            throw LifeLogError.activityNotAvailable
        }

        return await withCheckedContinuation { continuation in
            activityManager.queryActivityStarting(from: startDate, to: endDate, to: .main) { activities, _ in
                let records = (activities ?? []).compactMap { activity -> ActivityRecord? in
                    let activityType: ActivityType
                    if activity.running {
                        activityType = .running
                    } else if activity.cycling {
                        activityType = .cycling
                    } else if activity.automotive {
                        activityType = .driving
                    } else if activity.walking {
                        activityType = .walking
                    } else if activity.stationary {
                        activityType = .stationary
                    } else {
                        return nil
                    }

                    let confidence: Double
                    switch activity.confidence {
                    case .high: confidence = 1.0
                    case .medium: confidence = 0.6
                    case .low: confidence = 0.3
                    @unknown default: confidence = 0.3
                    }

                    return ActivityRecord(
                        startDate: activity.startDate,
                        endDate: activity.startDate,
                        activityType: activityType,
                        confidence: confidence
                    )
                }
                continuation.resume(returning: records)
            }
        }
    }
}
