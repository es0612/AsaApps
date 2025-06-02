// AsaApps/Apps/AsaMoodTracker/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedEmoji = "😊"
    @State private var moodEntries: [MoodEntry] = []
    let emojis = ["😊", "😢", "😤", "😍", "😴"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image("AsaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                Text("アサパパの気分記録")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.asaCoffeeBrown)
                
                Picker("気分を選択", selection: $selectedEmoji) {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji).tag(emoji)
                    }
                }
                .pickerStyle(.menu)
                .tint(.asaMutedSage)
                .background(.asaSoftCream.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                
                Button("記録する") {
                    let newEntry = MoodEntry(date: Date(), emoji: selectedEmoji)
                    moodEntries.append(newEntry)
                    saveToUserDefaults()
                }
                .font(.title2.weight(.medium))
                .padding()
                .background(.asaCoffeeBrown)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 2)
                
                NavigationLink("履歴を見る", destination: MoodHistoryView(entries: moodEntries))
                    .font(.title2.weight(.medium))
                    .foregroundColor(.asaMutedSage)
            }
            .padding()
            .background(.asaSoftCream)
            .onAppear {
                loadFromUserDefaults()
            }
        }
    }
    
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(data, forKey: "moodEntries")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
           let savedEntries = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = savedEntries
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
