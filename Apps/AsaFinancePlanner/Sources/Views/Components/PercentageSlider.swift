import SwiftUI
import AsaUIKit

struct PercentageSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0.0...0.20
    var step: Double = 0.005

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AsaColors.darkSlate)

                Spacer()

                Text(formattedPercentage)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }

            Slider(value: $value, in: range, step: step)
                .tint(AsaColors.coffeeBrown)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)、\(formattedPercentage)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
            case .decrement:
                value = max(value - step, range.lowerBound)
            @unknown default:
                break
            }
        }
    }

    private var formattedPercentage: String {
        String(format: "%.1f%%", value * 100)
    }
}
