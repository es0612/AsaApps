import SwiftUI
import AsaLifeLogKit

// MARK: - ActivityIcon

/// アクティビティ種別のSFシンボルアイコン
struct ActivityIcon: View {
    let activityType: ActivityType
    var size: CGFloat = 20

    var body: some View {
        Image(systemName: activityType.icon)
            .font(.system(size: size))
            .foregroundStyle(iconColor)
    }

    private var iconColor: Color {
        switch activityType {
        case .stationary: return .gray
        case .walking: return .blue
        case .running: return .orange
        case .cycling: return .green
        case .driving: return .purple
        }
    }
}
