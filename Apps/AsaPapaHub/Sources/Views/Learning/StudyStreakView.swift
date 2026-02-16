import SwiftUI
import AsaUIKit

// MARK: - 学習ストリークビュー

/// 連続学習日数の表示
struct StudyStreakView: View {
    // サンプルデータ
    private let streakDays = 12
    private let weekData: [(String, Bool)] = [
        ("月", true),
        ("火", true),
        ("水", true),
        ("木", true),
        ("金", false),
        ("土", true),
        ("日", true),
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // ストリークカウンター
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading) {
                    Text("\(streakDays)日連続")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("学習ストリーク継続中！")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // 週間カレンダー
            HStack(spacing: 8) {
                ForEach(weekData, id: \.0) { day in
                    VStack(spacing: 4) {
                        Text(day.0)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(day.1 ? Color.purple : Color.gray.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay {
                                if day.1 {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }
}
