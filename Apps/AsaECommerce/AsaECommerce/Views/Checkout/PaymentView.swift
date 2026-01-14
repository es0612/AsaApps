import SwiftUI
import AsaUIKit

struct PaymentView: View {
    @Binding var selectedMethod: PaymentMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("支払い方法")
                .font(.title2.bold())
                .foregroundColor(AsaColors.darkSlate)

            VStack(spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodRow(
                        method: method,
                        isSelected: selectedMethod == method,
                        onSelect: {
                            selectedMethod = method
                        }
                    )
                }
            }

            // 注意事項
            VStack(alignment: .leading, spacing: 8) {
                Text("ご注意")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)

                Text("・これは模擬的な決済機能です\n・実際の課金は発生しません\n・テスト用のデータとしてご利用ください")
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            }
            .padding()
            .background(AsaColors.softCream)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Payment Method Row

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: method.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                    .frame(width: 40)

                Text(method.displayName)
                    .font(.body.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage)
            }
            .padding()
            .background(isSelected ? AsaColors.softCream : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaymentView(selectedMethod: .constant(.creditCard))
        .padding()
        .background(AsaColors.softCream.opacity(0.3))
}
