import SwiftUI
import AsaUIKit

struct DigitalClockView: View {
    let timeZone: TimeZone
    @Environment(TimeZoneViewModel.self) private var viewModel

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: viewModel.currentTime)
    }

    private var amPmString: String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "a"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: viewModel.currentTime)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(.system(size: 42, weight: .light, design: .monospaced))
                .foregroundColor(AsaColors.darkSlate)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(amPmString)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AsaColors.mutedSage)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AsaColors.softCream)
                .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}