import SwiftUI
import AsaUIKit

struct ShippingFormView: View {
    @Binding var address: ShippingAddress

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("配送先情報")
                .font(.title2.bold())
                .foregroundColor(AsaColors.darkSlate)

            VStack(spacing: 16) {
                // 氏名
                FormField(title: "氏名", text: $address.fullName, placeholder: "山田 太郎")

                // 電話番号
                FormField(title: "電話番号", text: $address.phoneNumber, placeholder: "090-1234-5678")
                    .keyboardType(.phonePad)

                // 郵便番号
                FormField(title: "郵便番号", text: $address.postalCode, placeholder: "123-4567")
                    .keyboardType(.numbersAndPunctuation)

                // 都道府県
                VStack(alignment: .leading, spacing: 6) {
                    Text("都道府県")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AsaColors.darkSlate)

                    Picker("都道府県", selection: $address.prefecture) {
                        Text("選択してください").tag("")
                        ForEach(ShippingAddress.prefectures, id: \.self) { pref in
                            Text(pref).tag(pref)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AsaColors.mutedSage.opacity(0.3), lineWidth: 1)
                    )
                }

                // 市区町村
                FormField(title: "市区町村", text: $address.city, placeholder: "渋谷区")

                // 番地
                FormField(title: "番地", text: $address.addressLine1, placeholder: "1-2-3")

                // 建物名（任意）
                FormField(title: "建物名・部屋番号（任意）", text: Binding(
                    get: { address.addressLine2 ?? "" },
                    set: { address.addressLine2 = $0.isEmpty ? nil : $0 }
                ), placeholder: "〇〇マンション 101号室")
            }
        }
    }
}

// MARK: - Form Field

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(AsaColors.darkSlate)

            TextField(placeholder, text: $text)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AsaColors.mutedSage.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ScrollView {
        ShippingFormView(address: .constant(ShippingAddress()))
            .padding()
    }
    .background(AsaColors.softCream.opacity(0.3))
}
