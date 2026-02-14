import SwiftUI
import MapKit
import AsaUIKit
import AsaCommunityKit

/// 近隣マップ画面
struct NeighborhoodMapView: View {
    @Bindable var viewModel: NeighborhoodMapViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Map
                Map(position: $cameraPosition) {
                    // 投稿マーカー
                    if viewModel.showPosts {
                        ForEach(viewModel.filteredPosts) { post in
                            if let lat = post.latitude, let lon = post.longitude {
                                Annotation(post.title, coordinate: CLLocationCoordinate2D(
                                    latitude: lat, longitude: lon
                                )) {
                                    MapAnnotationView(
                                        iconName: post.category.iconName,
                                        color: AsaColors.coffeeBrown
                                    )
                                }
                            }
                        }
                    }

                    // イベントマーカー
                    if viewModel.showEvents {
                        ForEach(viewModel.events.filter { !$0.isPast }) { event in
                            Annotation(event.title, coordinate: CLLocationCoordinate2D(
                                latitude: event.latitude, longitude: event.longitude
                            )) {
                                MapAnnotationView(
                                    iconName: "calendar",
                                    color: .orange
                                )
                            }
                        }
                    }

                    // 店舗マーカー
                    if viewModel.showBusinesses {
                        ForEach(viewModel.businesses) { business in
                            Annotation(business.name, coordinate: CLLocationCoordinate2D(
                                latitude: business.latitude, longitude: business.longitude
                            )) {
                                MapAnnotationView(
                                    iconName: business.category.iconName,
                                    color: .green
                                )
                            }
                        }
                    }

                    // 避難所マーカー
                    if viewModel.showShelters {
                        ForEach(viewModel.shelters) { shelter in
                            Annotation(shelter.name, coordinate: CLLocationCoordinate2D(
                                latitude: shelter.latitude, longitude: shelter.longitude
                            )) {
                                MapAnnotationView(
                                    iconName: "cross.case.fill",
                                    color: .red
                                )
                            }
                        }
                    }

                    UserAnnotation()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }

                // MARK: - Filter Overlay
                VStack {
                    Spacer()
                    filterBar
                }
            }
            .navigationTitle("マップ")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadMapData()
                viewModel.requestLocationPermission()
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterToggle("投稿", iconName: "bubble.left", isOn: $viewModel.showPosts)
                filterToggle("イベント", iconName: "calendar", isOn: $viewModel.showEvents)
                filterToggle("お店", iconName: "building.2", isOn: $viewModel.showBusinesses)
                filterToggle("避難所", iconName: "cross.case", isOn: $viewModel.showShelters)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }

    private func filterToggle(_ label: String, iconName: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Label(label, systemImage: iconName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isOn.wrappedValue ? AsaColors.coffeeBrown : Color(.systemGray5))
                .foregroundStyle(isOn.wrappedValue ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
