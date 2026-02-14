import SwiftUI
import AsaLifeLogKit

// MARK: - PlaceListView

/// 場所一覧ビュー
struct PlaceListView: View {
    @Bindable var viewModel: PlaceLogViewModel

    var body: some View {
        List {
            if viewModel.places.isEmpty {
                ContentUnavailableView(
                    "場所データなし",
                    systemImage: "mappin.slash",
                    description: Text("位置情報トラッキングを有効にすると、訪問場所が記録されます")
                )
            } else {
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    let places = viewModel.placesByCategory[category] ?? []
                    if !places.isEmpty {
                        Section(category.displayName) {
                            ForEach(places, id: \.id) { place in
                                NavigationLink {
                                    PlaceDetailView(place: place)
                                } label: {
                                    HStack {
                                        Image(systemName: category.icon)
                                            .foregroundStyle(.blue)
                                            .frame(width: 30)

                                        VStack(alignment: .leading) {
                                            Text(place.name)
                                                .font(.subheadline.weight(.medium))
                                            Text("訪問回数: \(place.visitCount)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if place.isFavorite {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .swipeActions {
                                    Button {
                                        Task { await viewModel.toggleFavorite(place) }
                                    } label: {
                                        Label("お気に入り", systemImage: place.isFavorite ? "star.slash" : "star")
                                    }
                                    .tint(.yellow)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("訪問場所")
        .task {
            await viewModel.loadPlaces()
        }
    }
}
