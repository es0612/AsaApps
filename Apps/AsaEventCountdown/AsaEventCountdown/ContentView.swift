// AsaApps/Apps/AsaEventCountdown/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var viewModel = EventViewModel()
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.asaSoftCream
                    .ignoresSafeArea()
                VStack(spacing: 28) {
                    Spacer(minLength: 20)
                    Image("AsaPapaLabLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                    Text("アサパパのイベントカウントダウン")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                        .padding(.bottom, 8)
                    VStack(spacing: 12) {
                        TextField("イベント名（例：誕生日）", text: $viewModel.eventName)
                            .padding()
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.asaMutedSage, lineWidth: 1)
                            )
                            .frame(maxWidth: 340)
                        if viewModel.eventName.isEmpty && showError {
                            Text("イベント名を入力してください")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                        }
                    }
                    DatePicker("イベント日", selection: $viewModel.eventDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(.asaMutedSage)
                        .padding(.horizontal)
                        .frame(maxWidth: 340)
                    Text("あと \(viewModel.daysUntilEvent(from: viewModel.eventDate)) 日！")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                        .padding(.top, 8)
                    Button("保存") {
                        showError = viewModel.eventName.isEmpty
                        viewModel.addEvent()
                    }
                    .font(.title2.weight(.medium))
                    .frame(maxWidth: 340)
                    .padding()
                    .background(Color.asaCoffeeBrown)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 2)
                    NavigationLink("イベント一覧", destination: EventListView())
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaMutedSage)
                        .frame(maxWidth: 340)
                        .padding(.top, 4)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .onAppear {
                    viewModel.loadFromUserDefaults()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
