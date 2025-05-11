import SwiftUI

struct ContentView: View {
    @State private var landmarksState: [Landmark] = landmarks // 状態を管理
    @State private var showFavoritesOnly = false // お気に入りのみ表示
    
    var filteredLandmarks: [Landmark] {
        landmarksState.filter { landmark in
            !showFavoritesOnly || landmark.isFavorite
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Toggle(isOn: $showFavoritesOnly) {
                    Text("お気に入りのみ表示")
                        .foregroundColor(.blue)
                }
                .padding()
                List {
                    ForEach(filteredLandmarks.indices, id: \.self) { index in
                        let landmark = filteredLandmarks[index]
                        NavigationLink(destination: LandmarkDetail(landmark: landmark)) {
                            LandmarkRow(
                                landmark: landmark,
                                isFavorite: $landmarksState[
                                    landmarksState.firstIndex(where: { $0.id == landmark.id })!
                                ].isFavorite
                            )
                        }
                    }
                }
                .navigationTitle("Landmarks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}



#Preview {
    ContentView()
}
