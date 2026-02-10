import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct InsightCard: View {
    let insight: FinancialInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AsaColors.darkSlate)

                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(typeLabel)、\(insight.title)、\(insight.message)")
    }

    private var iconColor: Color {
        switch insight.type {
        case .warning: return .orange
        case .suggestion: return AsaColors.coffeeBrown
        case .achievement: return .green
        case .info: return .blue
        }
    }

    private var cardBackground: Color {
        switch insight.type {
        case .warning: return .orange.opacity(0.05)
        case .suggestion: return AsaColors.softCream.opacity(0.3)
        case .achievement: return .green.opacity(0.05)
        case .info: return .blue.opacity(0.05)
        }
    }

    private var typeLabel: String {
        switch insight.type {
        case .warning: return "警告"
        case .suggestion: return "提案"
        case .achievement: return "達成"
        case .info: return "情報"
        }
    }
}
