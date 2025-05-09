import SwiftUI

struct LandmarkRow: View {
    let landmark: Landmark

       var body: some View {
           HStack {
               Image("AsaLogo")
                   .resizable()
                   .scaledToFit()
                   .frame(width: 50, height: 50)
                   .clipShape(Circle())
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
    LandmarkRow(landmark: landmarks[0])
}
