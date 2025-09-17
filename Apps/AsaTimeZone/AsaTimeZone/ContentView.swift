import SwiftUI
import AsaUIKit

struct ContentView: View {
    @Environment(TimeZoneViewModel.self) private var viewModel
    @State private var showingAddTimeZone = false
    @State private var showingSettings = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.timeZoneItems) { item in
                        TimeZoneCardView(timeZoneItem: item)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.toggleClockStyle(for: item)
                                }
                            }
                    }

                    if viewModel.timeZoneItems.count < 6 {
                        AddTimeZoneButton {
                            showingAddTimeZone = true
                        }
                    }
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.2))
            .navigationTitle("世界時計")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
            .sheet(isPresented: $showingAddTimeZone) {
                AddTimeZoneView()
                    .environment(viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(viewModel)
            }
        }
    }
}

struct AddTimeZoneButton: View {
    let action: () -> Void

    var body: some View {
        AsaCard {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AsaColors.coffeeBrown)

                Text("タイムゾーンを追加")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
        }
        .onTapGesture {
            action()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(TimeZoneViewModel())
    }
}