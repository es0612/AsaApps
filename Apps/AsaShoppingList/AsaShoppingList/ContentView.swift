import SwiftUI

struct ContentView: View {
    @State private var shoppingListManager = ShoppingListManager()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                .opacity(colorScheme == .dark ? 0.9 : 0.1)
                .ignoresSafeArea()
            Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                .opacity(colorScheme == .dark ? 0.2 : 0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("AsaShoppingList")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                // 買い物リスト
                List {
                    ForEach(shoppingListManager.items) { item in
                        HStack {
                            Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                .foregroundColor(item.isCompleted ? Color("AsaMocha") : .gray)
                                .onTapGesture {
                                    shoppingListManager.toggleCompletion(for: item)
                                }

                            Text(item.name)
                                .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))
                                .strikethrough(item.isCompleted, color: .gray)

                            Spacer()
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color("AsaDarkSlate").opacity(0.8) : Color.white.opacity(0.8))
                                .shadow(radius: 2)
                        )
                        
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden) // リストの背景を透明に
                .background(
                                    colorScheme == .dark ?
                                        Color("AsaDarkSlate").opacity(0.9).ignoresSafeArea() :
                                        Color("AsaSoftCream").opacity(0.1).ignoresSafeArea()
                                )
                

                Spacer()
            }
            .padding(.top)
        }
    }
}

#Preview {
    ContentView()
}
