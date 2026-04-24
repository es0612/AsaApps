import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

/// 家系図の凡例ビュー（折りたたみ可能、ScrollView の外側に置くため zoom/pan の影響を受けない）
struct TreeLegendView: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if isExpanded {
                expandedPanel
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            toggleButton
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    // MARK: - Toggle Button

    private var toggleButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            Image(systemName: isExpanded ? "xmark" : "info.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AsaColors.coffeeBrown)
                .padding(10)
                .background(
                    Circle()
                        .fill(AsaColors.cardBackground)
                        .shadow(color: AsaColors.mocha.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
        .accessibilityLabel(isExpanded ? "凡例を閉じる" : "凡例を開く")
    }

    // MARK: - Expanded Panel

    private var expandedPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("凡例")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(AsaColors.mocha)

            Group {
                lineRow(type: .parentChild, label: "親子")
                lineRow(type: .siblingBus, label: "兄弟姉妹")
                lineRow(type: .currentSpouse, label: "配偶者")
                lineRow(type: .divorcedSpouse, label: "離別配偶者")
            }

            Divider()
                .background(AsaColors.mocha.opacity(0.3))

            Group {
                genderRow(gender: .male, label: "男性")
                genderRow(gender: .female, label: "女性")
                genderRow(gender: .other, label: "その他")
            }

            Divider()
                .background(AsaColors.mocha.opacity(0.3))

            deceasedRow
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AsaColors.cardBackground)
                .shadow(color: AsaColors.mocha.opacity(0.2), radius: 6, x: 0, y: 3)
        )
        .padding(.bottom, 8)
    }

    // MARK: - Row Helpers

    @ViewBuilder
    private func lineRow(type: ConnectionType, label: String) -> some View {
        HStack(spacing: 8) {
            linePreview(type: type)
                .frame(width: 40, height: 14)
            Text(label)
                .font(.caption)
                .foregroundStyle(AsaColors.darkSlate)
        }
    }

    private func linePreview(type: ConnectionType) -> some View {
        Canvas { context, size in
            let y = size.height / 2
            let from = CGPoint(x: 0, y: y)
            let to = CGPoint(x: size.width, y: y)
            let strokeStyle = type.strokeStyle()
            let color = GraphicsContext.Shading.color(type.swiftUIColor)

            if type.isDouble {
                let offset: CGFloat = 2.0
                var path1 = Path()
                path1.move(to: CGPoint(x: from.x, y: from.y - offset))
                path1.addLine(to: CGPoint(x: to.x, y: to.y - offset))
                var path2 = Path()
                path2.move(to: CGPoint(x: from.x, y: from.y + offset))
                path2.addLine(to: CGPoint(x: to.x, y: to.y + offset))
                context.stroke(path1, with: color, style: strokeStyle)
                context.stroke(path2, with: color, style: strokeStyle)
            } else {
                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                context.stroke(path, with: color, style: strokeStyle)
            }
        }
    }

    private func genderRow(gender: Gender, label: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(gender.nodeBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(gender.nodeBorderColor, lineWidth: 2)
                )
                .frame(width: 40, height: 14)
            Text(label)
                .font(.caption)
                .foregroundStyle(AsaColors.darkSlate)
        }
    }

    private var deceasedRow: some View {
        HStack(spacing: 8) {
            Text("没")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AsaColors.mocha)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AsaColors.softCream)
                )
                .frame(width: 40, alignment: .leading)
            Text("故人")
                .font(.caption)
                .foregroundStyle(AsaColors.darkSlate)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                TreeLegendView()
                    .padding()
            }
        }
    }
}
