import SwiftUI

struct LandmarkList: View {
    @State private var landmarksState: [Landmark] = landmarksdata
    @EnvironmentObject var modelData: ModelData
    @State private var showFavoritesOnly = false
    @State private var filterOption: FilterOption = .all
    @State private var editMode = EditMode.inactive


    enum FilterOption: String, CaseIterable {
        case all = "すべて"
        case favorites = "お気に入り"
        case featured = "注目の場所"
    }
    
    private func deleteItems(at offsets: IndexSet) {
        modelData.landmarks.remove(atOffsets: offsets)
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        modelData.landmarks.move(fromOffsets: source, toOffset: destination)
    }

    var filteredLandmarks: [Landmark] {
        modelData.landmarks.filter { landmark in
            switch filterOption {
            case .all:
                return true
            case .favorites:
                return landmark.isFavorite
            case .featured:
                return landmark.isFeatured
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("フィルター", selection: $filterOption) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    ForEach(filteredLandmarks) { landmark in
                        NavigationLink(destination: LandmarkDetail(landmark: landmark)) {
                            LandmarkRow(landmark: landmark,  isFavorite: $landmarksState[
                                landmarksState.firstIndex(where: { $0.id == landmark.id })!
                            ].isFavorite)
                        }
                    }
                    .onDelete(perform: deleteItems)
                    .onMove(perform: moveItems)
                }
                .navigationTitle("Landmarks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
                .environment(\.editMode, $editMode)
            
            }
        }
    }
}

#Preview {
    LandmarkList()
        .environmentObject(ModelData())
}
