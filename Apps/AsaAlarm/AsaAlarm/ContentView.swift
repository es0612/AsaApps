import SwiftUI

struct ContentView: View {
    @State private var viewModel = AlarmViewModel()
    @State private var showingAddAlarm = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("AsaSoftCream").opacity(0.1)
                    .ignoresSafeArea()
                
                if viewModel.alarms.isEmpty {
                    emptyStateView
                } else {
                    alarmListView
                }
            }
            .navigationTitle("アラーム")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAlarm = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView { alarm in
                    viewModel.addAlarm(alarm)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 8) {
                Text("アラームがありません")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("右上の + ボタンからアラームを追加できます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingAddAlarm = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新しいアラーム")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color("AsaCoffeeBrown"))
                .cornerRadius(25)
            }
        }
        .padding()
    }
    
    private var alarmListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.alarms.sorted(by: { $0.time < $1.time })) { alarm in
                    AlarmRowView(
                        alarm: alarm,
                        onToggle: {
                            viewModel.toggleAlarm(alarm)
                        },
                        onDelete: {
                            viewModel.deleteAlarm(alarm)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

#Preview {
    ContentView()
}
