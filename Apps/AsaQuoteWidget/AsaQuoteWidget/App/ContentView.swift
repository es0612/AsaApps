import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            QuoteListView()
                .tabItem {
                    Image(systemName: "quote.bubble")
                    Text("名言")
                }
                .tag(0)
            
            FavoriteQuotesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("お気に入り")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
                .tag(2)
        }
        .accentColor(Color("AsaCoffeeBrown"))
    }
}

#Preview {
    ContentView()
}