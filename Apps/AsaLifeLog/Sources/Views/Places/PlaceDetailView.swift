import SwiftUI
import MapKit
import AsaLifeLogKit

// MARK: - PlaceDetailView

/// 場所詳細ビュー
struct PlaceDetailView: View {
    let place: PlaceLog

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ミニマップ
                Map {
                    Marker(place.name, coordinate: CLLocationCoordinate2D(
                        latitude: place.latitude,
                        longitude: place.longitude
                    ))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                AsaLifeLogCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: place.category.icon)
                                .font(.title2)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading) {
                                Text(place.name)
                                    .font(.title3.weight(.bold))
                                Text(place.category.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        if let address = place.address {
                            LabeledContent("住所", value: address)
                                .font(.subheadline)
                        }

                        LabeledContent("訪問回数", value: "\(place.visitCount)回")
                            .font(.subheadline)

                        LabeledContent("初回訪問") {
                            Text(place.firstVisitedAt.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.subheadline)

                        LabeledContent("最終訪問") {
                            Text(place.lastVisitedAt.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.subheadline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(place.name)
    }
}
