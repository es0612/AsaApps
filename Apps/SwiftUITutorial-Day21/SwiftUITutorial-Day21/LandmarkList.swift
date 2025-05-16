import SwiftUI

struct LandmarkList: View {
    @State private var landmarksState: [Landmark] = landmarksdata
    @EnvironmentObject var modelData: ModelData
    @State private var showFavoritesOnly = false
    
    var filteredLandmarks: [Landmark] {
        modelData.landmarks.filter { landmark in
            !showFavoritesOnly || landmark.isFavorite
        }
    }
    
    var body: some View {
        VStack {
            Toggle(isOn: $showFavoritesOnly) {
                Text("お気に入りのみ表示")
                    .foregroundColor(.blue)
            }
            .padding()
            List {
                ForEach(filteredLandmarks) { landmark in
                    NavigationLink(destination: LandmarkDetail(landmark: landmark)) {
                        LandmarkRow(landmark: landmark,  isFavorite: $landmarksState[
                            landmarksState.firstIndex(where: { $0.id == landmark.id })!
                        ].isFavorite)
                    }
                }
            }
            .navigationTitle("Landmarks")
        }
    }
}

#Preview {
    LandmarkList()
        .environmentObject(ModelData())
}
