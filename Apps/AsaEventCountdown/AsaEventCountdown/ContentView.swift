// AsaApps/Apps/AsaEventCountdown/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var eventDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image("AsaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                Text("アサパパのイベントカウントダウン")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.asaCoffeeBrown)
                
                DatePicker("イベント日", selection: $eventDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(.asaMutedSage)
                    .padding()
                
                Text("あと \(daysUntilEvent(from: eventDate)) 日！")
                    .font(.title3.weight(.medium))
                    .foregroundColor(.asaCoffeeBrown)
                
                Button("保存") {
                    // Day 2で実装
                }
                .font(.title2.weight(.medium))
                .padding()
                .background(.asaCoffeeBrown)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 2)
                
                NavigationLink("イベント一覧", destination: Text("未実装"))
                    .font(.title2.weight(.medium))
                    .foregroundColor(.asaMutedSage)
            }
            .padding()
            .background(.asaSoftCream)
        }
    }
    
    func daysUntilEvent(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return max(0, components.day ?? 0) // 過去の日付は0
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
