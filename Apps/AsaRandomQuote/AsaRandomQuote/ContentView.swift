import SwiftUI

struct ContentView: View {
    @State private var viewModel = QuoteViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image("AsaPapaLabLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .padding(.top, 20)
                        .shadow(radius: 1)
                    
                    Text("アサパパの名言集")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                    
                    AsaCard {
                        Text(viewModel.currentQuote.text)
                            .font(.body.weight(.medium))
                            .foregroundColor(.asaCoffeeBrown)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    Button(action: { viewModel.toggleFavorite() }) {
                        Image(systemName: viewModel.currentQuote.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(.asaMutedSage)
                            .font(.title2)
                    }
                    .padding(.bottom, 8)
                    
                    AsaButton(title: "Test Button", action: {
                        viewModel.getRandomQuote()
                    }, color: Color("AsaCoffeeBrown"))
                    .padding(.horizontal)
                    
                    
                    NavigationLink("お気に入りを見る", destination: FavoriteQuotesView())
                        .font(.body.weight(.medium))
                        .foregroundColor(.asaMutedSage)
                        .padding(.bottom, 20)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
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
