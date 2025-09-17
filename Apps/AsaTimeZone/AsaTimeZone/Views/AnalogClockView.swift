import SwiftUI
import AsaUIKit

struct AnalogClockView: View {
    let timeZone: TimeZone
    @EnvironmentObject private var viewModel: TimeZoneViewModel
    @State private var currentTime = Date()

    private var hourAngle: Angle {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timeZone, from: viewModel.currentTime)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        return Angle(degrees: (hour * 30) + (minute * 0.5) - 90)
    }

    private var minuteAngle: Angle {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timeZone, from: viewModel.currentTime)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        return Angle(degrees: (minute * 6) + (second * 0.1) - 90)
    }

    private var secondAngle: Angle {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timeZone, from: viewModel.currentTime)
        let second = Double(components.second ?? 0)
        return Angle(degrees: (second * 6) - 90)
    }

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2

            ZStack {
                Circle()
                    .stroke(AsaColors.mutedSage, lineWidth: 2)

                ForEach(0..<12) { hour in
                    let angle = Double(hour) * 30 - 90
                    let isMainHour = hour % 3 == 0

                    VStack {
                        if isMainHour {
                            Text("\(hour == 0 ? 12 : hour)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AsaColors.darkSlate)
                        } else {
                            Circle()
                                .fill(AsaColors.mutedSage)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .offset(y: -radius * 0.8)
                    .rotationEffect(Angle(degrees: Double(hour) * 30))
                }

                Rectangle()
                    .fill(AsaColors.coffeeBrown)
                    .frame(width: radius * 0.5, height: 4)
                    .offset(x: radius * 0.25)
                    .rotationEffect(hourAngle)

                Rectangle()
                    .fill(AsaColors.darkSlate)
                    .frame(width: radius * 0.7, height: 2)
                    .offset(x: radius * 0.35)
                    .rotationEffect(minuteAngle)

                Rectangle()
                    .fill(AsaColors.mocha)
                    .frame(width: radius * 0.8, height: 1)
                    .offset(x: radius * 0.4)
                    .rotationEffect(secondAngle)

                Circle()
                    .fill(AsaColors.coffeeBrown)
                    .frame(width: 8, height: 8)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}