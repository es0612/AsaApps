import SwiftUI

struct LandmarkRow: View {
    let landmark: Landmark
    @Binding var isFavorite: Bool // いいね状態をバインド

    var body: some View {
        HStack {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundColor(.yellow)
                .onTapGesture {
                    isFavorite.toggle() // タップで切り替え
                }
            Text(landmark.name)
                .font(.title3)
            Spacer()
            Text(landmark.state)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    LandmarkRow(landmark: landmarksdata[0], isFavorite: .constant(false))
}
