import SwiftUI

struct ContentView: View {
    @StateObject private var modelData = ModelData()
    
    var body: some View {
        NavigationView {
            LandmarkList()
            
        }
        .environmentObject(modelData)
        .environment(\.colorScheme, .dark)
    }
}

#Preview {
    ContentView()
}
