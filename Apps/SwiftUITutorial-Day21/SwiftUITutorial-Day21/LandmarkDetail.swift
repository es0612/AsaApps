import SwiftUI

struct LandmarkDetail: View {
    @EnvironmentObject var modelData: ModelData
    @Environment(\.colorScheme) var colorScheme
    var landmark: Landmark

    var landmarkIndex: Int {
        modelData.landmarks.firstIndex(where: { $0.id == landmark.id })!
    }

    var body: some View {
        VStack {
            Text(landmark.name)
                .font(.title)
                .foregroundColor(colorScheme == .dark ? .blue : .black)
            Toggle(isOn: $modelData.landmarks[landmarkIndex].isFavorite) {
                Text("お気に入り")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .navigationTitle(landmark.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LandmarkDetail(landmark: landmarksdata[0])
        .environmentObject(ModelData())
        .environment(\.colorScheme, .dark)
}
