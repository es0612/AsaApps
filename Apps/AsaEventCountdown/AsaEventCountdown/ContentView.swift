// AsaApps/Apps/AsaEventCountdown/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var viewModel = EventViewModel()
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image("AsaPapaLabLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                Text("アサパパのイベントカウントダウン")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.asaCoffeeBrown)
                
                TextField("イベント名（例：誕生日）", text: $viewModel.eventName)
                    .padding()
                    .border(.asaMutedSage, width: 1)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                if viewModel.eventName.isEmpty && showError {
                    Text("イベント名を入力してください")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                DatePicker("イベント日", selection: $viewModel.eventDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(.asaMutedSage)
                    .padding()
                
                Text("あと \(viewModel.daysUntilEvent(from: viewModel.eventDate)) 日！")
                    .font(.title3.weight(.medium))
                    .foregroundColor(.asaCoffeeBrown)
                
                Button("保存") {
                    showError = viewModel.eventName.isEmpty
                    viewModel.addEvent()
                }
                .font(.title2.weight(.medium))
                .padding()
                .background(.asaCoffeeBrown)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 2)
                
                NavigationLink("イベント一覧", destination: EventListView())
                    .font(.title2.weight(.medium))
                    .foregroundColor(.asaMutedSage)
            }
            .padding()
            .background(.asaSoftCream)
            .onAppear {
                viewModel.loadFromUserDefaults()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
