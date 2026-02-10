import SwiftUI
import AsaUIKit

struct CurrencyTextField: View {
    let title: String
    @Binding var value: Decimal
    var currencyCode: String = "JPY"

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AsaColors.mutedSage)

            HStack {
                Text(currencySymbol)
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .fontWeight(.semibold)

                TextField("0", text: $textValue)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .onChange(of: textValue) { _, newValue in
                        let filtered = newValue.filter(\.isNumber)
                        if filtered != newValue {
                            textValue = filtered
                        }
                        if let intVal = Int(filtered) {
                            value = Decimal(intVal)
                        } else {
                            value = .zero
                        }
                    }
            }
            .padding(12)
            .background(AsaColors.softCream.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? AsaColors.coffeeBrown : Color.clear, lineWidth: 1.5)
            )
        }
        .onAppear {
            let intValue = NSDecimalNumber(decimal: value).intValue
            textValue = intValue > 0 ? "\(intValue)" : ""
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)、\(formattedValue)")
    }

    private var currencySymbol: String {
        currencyCode == "JPY" ? "¥" : "$"
    }

    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
}
