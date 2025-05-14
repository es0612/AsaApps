import SwiftUI

struct ContentView: View {
    @State private var landmarksState: [Landmark] = landmarks
    @State private var showFavoritesOnly = false
    @State private var animationStates: [Int: Bool] = [:] // 各アイテムのアニメーション状態

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
                        ZStack {
                            if landmark.isFavorite {
                                Badge()
                                    .frame(width: 40, height: 40)
                                    .offset(x: -30, y: -20)
                                    .scaleEffect(animationStates[index] ?? false ? 1.0 : 0.8)
                                    .rotationEffect(.degrees(animationStates[index] ?? false ? 360 : 0))
                                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animationStates[index])
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                                            withAnimation {
                                                animationStates[index] = true
                                            }
                                        }
                                    }
                            }
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
