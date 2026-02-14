import SwiftUI
import MapKit
import AsaLifeLogKit

// MARK: - PlaceMapView

/// 場所マップビュー
struct PlaceMapView: View {
    @Bindable var viewModel: PlaceLogViewModel
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            ForEach(viewModel.places, id: \.id) { place in
                Annotation(place.name, coordinate: CLLocationCoordinate2D(
                    latitude: place.latitude,
                    longitude: place.longitude
                )) {
                    Image(systemName: place.category.icon)
                        .font(.caption)
                        .padding(6)
                        .background(.background)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
        }
        .navigationTitle("マップ")
        .task {
            await viewModel.loadPlaces()
        }
    }
}
