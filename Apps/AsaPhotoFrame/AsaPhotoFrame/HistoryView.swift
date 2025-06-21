import SwiftUI

struct HistoryView: View {
    @State private var viewModel = PhotoFrameViewModel()
    @State private var selectedFrame: PhotoFrame?

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.frames) { frame in
                    HStack {
                        if let image = frame.imageData.flatMap({ UIImage(data: $0) }) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
//                                        .stroke(Color(hex: frame.frameColorHex), lineWidth: frame.frameWidth)
                                )
                        }
                        Text("Frame \(frame.id.uuidString.prefix(8))")
                            .foregroundColor(.asaCoffeeBrown)
                        Spacer()
                        Button(action: {
                            if let index = viewModel.frames.firstIndex(where: { $0.id == frame.id }) {
                                viewModel.frames.remove(at: index)
                                viewModel.saveToUserDefaults()
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.asaMutedSage)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("保存履歴")
            .background(LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom))
            .onAppear {
                viewModel.loadFromUserDefaults()
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
