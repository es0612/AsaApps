import SwiftUI

struct LandmarkDetail: View {
    let landmark: Landmark

    var body: some View {
            VStack {
                Image("AsaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                Text(landmark.name)
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text(landmark.park)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(landmark.description)
                    .padding()
                Spacer()
            }
            .padding()
            .navigationTitle(landmark.name)
        }
}

#Preview {
    LandmarkDetail(landmark: landmarks[0])
}
