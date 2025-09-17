import SwiftUI
import AsaUIKit

struct TimeZoneCardView: View {
    let timeZoneItem: TimeZoneItem
    @EnvironmentObject private var viewModel: TimeZoneViewModel

    var body: some View {
        AsaCard {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timeZoneItem.cityName)
                            .font(.headline)
                            .foregroundColor(AsaColors.darkSlate)

                        Text(timeZoneItem.countryName)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    Spacer()

                    Text(timeZoneItem.offset)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AsaColors.softCream)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                if timeZoneItem.clockStyle == .analog {
                    AnalogClockView(timeZone: timeZoneItem.timeZone)
                        .frame(height: 120)
                        .padding()
                } else {
                    DigitalClockView(timeZone: timeZoneItem.timeZone)
                        .frame(height: 120)
                        .padding()
                }

                Text(viewModel.dateString(for: timeZoneItem))
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                    .padding(.bottom, 12)
            }
        }
    }
}