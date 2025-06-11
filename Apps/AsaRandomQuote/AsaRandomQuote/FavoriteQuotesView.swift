import SwiftUI

struct FavoriteQuotesView: View {
    @State private var viewModel = QuoteViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                if viewModel.favoriteQuotes.isEmpty {
                    EmptyStateView()
                } else {
                    QuotesListView(viewModel: viewModel)
                }
            }
            .navigationTitle("お気に入りの名言")
            .onAppear {
                viewModel.loadFromUserDefaults()
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        Text("お気に入りの名言がありません")
            .font(.body.weight(.medium))
            .foregroundColor(.asaMocha)
            .padding()
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(radius: 2)
    }
}

private struct QuotesListView: View {
    @State var viewModel: QuoteViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.favoriteQuotes) { quote in
                QuoteRowView(quote: quote)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                let quotesToDelete = indexSet.map { viewModel.favoriteQuotes[$0] }
                quotesToDelete.forEach { viewModel.deleteFavoriteQuote($0) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.asaSoftCream)
        .padding(.horizontal)
    }
}

private struct QuoteRowView: View {
    let quote: Quote
    
    var body: some View {
        HStack {
            Text(quote.text)
                .font(.body.weight(.medium))
                .foregroundColor(.asaCoffeeBrown)
                .multilineTextAlignment(.leading)
            Spacer()
            Text("\(quote.timestamp, format: .dateTime)")
                .font(.caption)
                .foregroundColor(.asaMutedSage)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 2)
    }
}

struct FavoriteQuotesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteQuotesView()
    }
}
