import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - ドメインサマリーカード

/// ダッシュボードグリッドで使う共通サマリーカード。
/// 全 6 ドメインで同じレイアウト・同じ高さに揃えるための単一実装。
struct DomainSummaryCard<Destination: View>: View {
    let domain: LifeDomain
    let snapshot: DomainSnapshot?
    /// 健康カードの「8,399歩 ・ 7.7時間」のような補助メタ情報。snapshot.summary の上に小さく表示
    var subtitle: String?
    @ViewBuilder var destination: () -> Destination

    // MARK: - Body

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            DomainSectionHeader(domain: domain, showChevron: true)

            if let snapshot {
                Text("\(snapshot.score)点")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.darkSlate)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(snapshot.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer(minLength: 0)

                TrendIndicator(trend: snapshot.trend)
            } else {
                Text("--")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 168)
        .hubCardStyle()
    }
}
