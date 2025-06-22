import SwiftUI

struct HeaderView: View {
    var body: some View {
        Image("AsaPapaLabLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .shadow(radius: 1)
        Text("アサパパの三目並べ")
            .font(.title2.weight(.medium))
            .foregroundColor(.asaCoffeeBrown)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
    }
}
