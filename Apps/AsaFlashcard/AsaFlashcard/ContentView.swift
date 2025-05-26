import SwiftUI

struct ContentView: View {
    @StateObject private var flashcardManager = FlashcardManager()
    @State private var isFlipped: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                .opacity(colorScheme == .dark ? 0.9 : 0.1)
                .ignoresSafeArea()
            Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                .opacity(colorScheme == .dark ? 0.2 : 0.8)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("AsaFlashcard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                // フラッシュカード
                ZStack {
                    // カード背景
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 250, height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        .shadow(radius: 5)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )

                    // カードの表（word）
                    Text(flashcardManager.currentCard.word)
                        .font(.title)
                        .foregroundColor(.black)
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )

                    // カードの裏（meaning）
                    Text(flashcardManager.currentCard.meaning)
                        .font(.title)
                        .foregroundColor(.black)
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        // フリップ時に文字の向きを補正
                        .rotation3DEffect(
                            .degrees(isFlipped ? -180 : 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isFlipped.toggle()
                    }
                }

                // カード移動ボタン
                HStack(spacing: 50) {
                    Button(action: {
                        withAnimation {
                            flashcardManager.previousCard()
                            isFlipped = false
                        }
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title)
                            .foregroundColor(flashcardManager.currentIndex > 0 ? Color("AsaMocha") : .gray)
                    }
                    .disabled(flashcardManager.currentIndex == 0)

                    Button(action: {
                        withAnimation {
                            flashcardManager.nextCard()
                            isFlipped = false
                        }
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title)
                            .foregroundColor(flashcardManager.currentIndex < flashcardManager.flashcards.count - 1 ? Color("AsaMocha") : .gray)
                    }
                    .disabled(flashcardManager.currentIndex == flashcardManager.flashcards.count - 1)
                }

                // 現在のカード番号
                Text("カード \(flashcardManager.currentIndex + 1) / \(flashcardManager.flashcards.count)")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream").opacity(0.7) : Color("AsaCoffeeBrown").opacity(0.7))

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
