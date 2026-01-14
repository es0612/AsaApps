import SwiftUI
import AsaUIKit

struct QuantitySelector: View {
    @Binding var quantity: Int
    let minValue: Int
    let maxValue: Int

    init(quantity: Binding<Int>, minValue: Int = 1, maxValue: Int = 99) {
        self._quantity = quantity
        self.minValue = minValue
        self.maxValue = maxValue
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if quantity > minValue {
                    quantity -= 1
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(quantity > minValue ? AsaColors.coffeeBrown : AsaColors.mutedSage)
            }
            .disabled(quantity <= minValue)

            Text("\(quantity)")
                .font(.title3.bold())
                .foregroundColor(AsaColors.darkSlate)
                .frame(minWidth: 40)

            Button {
                if quantity < maxValue {
                    quantity += 1
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(quantity < maxValue ? AsaColors.coffeeBrown : AsaColors.mutedSage)
            }
            .disabled(quantity >= maxValue)
        }
    }
}

#Preview {
    @Previewable @State var quantity = 1
    QuantitySelector(quantity: $quantity)
        .padding()
}
