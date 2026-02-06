import AsaSmartReminderKit
import AsaUIKit
import MapKit
import SwiftUI

// MARK: - 地図概要ビュー

struct MapOverviewView: View {
    let viewModel: SmartReminderViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    // ユーザー位置
                    UserAnnotation()

                    // 各場所のジオフェンス表示
                    ForEach(viewModel.locations) { location in
                        // ジオフェンス範囲の円
                        MapCircle(
                            center: location.coordinate,
                            radius: location.radius
                        )
                        .foregroundStyle(circleColor(for: location).opacity(0.2))
                        .stroke(circleColor(for: location), lineWidth: 2)

                        // 場所のアノテーション
                        Annotation(location.name, coordinate: location.coordinate) {
                            GeofenceAnnotationView(location: location)
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }

                // 場所数インジケーター
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        locationCountBadge
                            .padding()
                    }
                }
            }
            .navigationTitle("地図")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - ヘルパー

    private func circleColor(for location: ReminderLocation) -> Color {
        if location.activeReminderCount > 0 {
            return AsaColors.coffeeBrown
        }
        return AsaColors.mutedSage
    }

    private var locationCountBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
            Text("\(viewModel.locations.count)箇所")
                .fontWeight(.medium)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - ジオフェンスアノテーション

struct GeofenceAnnotationView: View {
    let location: ReminderLocation

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(location.activeReminderCount > 0 ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                    .frame(width: 36, height: 36)
                Image(systemName: location.category.systemImageName)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            if location.activeReminderCount > 0 {
                Text("\(location.activeReminderCount)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(3)
                    .background(AsaColors.coffeeBrown)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .offset(y: -8)
            }
        }
    }
}
