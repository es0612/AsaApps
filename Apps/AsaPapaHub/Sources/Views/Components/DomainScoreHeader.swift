import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - ドメインスコアヘッダー

/// 各ドメイン詳細画面の上部に置くスコアヘッダー。
/// snapshot.score / trend / summary を ScoreRing と並べて統一フォーマットで表示する。
struct DomainScoreHeader: View {
    let domain: LifeDomain
    let snapshot: DomainSnapshot
    let gradientColors: [Color]

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(domain.displayName)スコア")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(snapshot.score)点")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.darkSlate)

                TrendIndicator(trend: snapshot.trend)

                if !snapshot.summary.isEmpty {
                    Text(snapshot.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            ScoreRing(
                progress: Double(snapshot.score) / 100.0,
                lineWidth: 8,
                size: 72,
                gradientColors: gradientColors
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hubCardStyle()
    }
}
