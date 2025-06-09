import SwiftUI

struct ConversionListView: View {
    @State private var viewModel = UnitConverterViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                if viewModel.conversions.isEmpty {
                    Text("履歴がありません")
                        .font(.body.weight(.medium))
                        .foregroundColor(.asaMocha)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.conversions) { conversion in
                            HStack {
                                Text("\(conversion.inputValue, specifier: "%.2f") \(conversion.unitType.components(separatedBy: "→")[0]) → \(conversion.outputValue, specifier: "%.3f") \(conversion.unitType.components(separatedBy: "→")[1])")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.asaCoffeeBrown)
                                Spacer()
                                Text("\(conversion.timestamp, format: .dateTime)")
                                    .font(.caption)
                                    .foregroundColor(.asaMutedSage)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .background(.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
                }
            }
            .navigationTitle("変換履歴")
            .onAppear {
                viewModel.loadFromUserDefaults()
            }
        }
    }
}

struct ConversionListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversionListView()
    }
}
