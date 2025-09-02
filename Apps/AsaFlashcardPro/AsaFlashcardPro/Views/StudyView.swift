import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let flashcards: [Flashcard]
    let studyMode: StudyMode
    
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var showingResult = false
    @State private var studySession = StudySession()
    @State private var dragOffset: CGSize = .zero
    @State private var showingProgress = false
    
    private var currentFlashcard: Flashcard? {
        guard currentIndex < flashcards.count else { return nil }
        return flashcards[currentIndex]
    }
    
    private var progress: Double {
        guard !flashcards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(flashcards.count)
    }
    
    enum StudyMode {
        case review, category(Category), bookmarked, hard, random, quick
        
        var title: String {
            switch self {
            case .review:
                return "復習モード"
            case .category(let category):
                return category.name
            case .bookmarked:
                return "お気に入り"
            case .hard:
                return "難しい単語"
            case .random:
                return "ランダム学習"
            case .quick:
                return "クイック学習"
            }
        }
        
        var color: String {
            switch self {
            case .review:
                return "AsaMocha"
            case .category(let category):
                return category.color
            case .bookmarked:
                return "AsaMutedSage"
            case .hard:
                return "AsaDarkSlate"
            case .random, .quick:
                return "AsaCoffeeBrown"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color("AsaSoftCream")
                .opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ヘッダー
                StudyHeaderBar(
                    mode: studyMode,
                    progress: progress,
                    currentIndex: currentIndex,
                    totalCount: flashcards.count,
                    showingProgress: $showingProgress
                ) {
                    dismiss()
                }
                
                Spacer()
                
                // フラッシュカード
                if let flashcard = currentFlashcard {
                    StudyCardView(
                        flashcard: flashcard,
                        isFlipped: $isFlipped,
                        dragOffset: $dragOffset
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                handleSwipeGesture(value)
                            }
                    )
                } else {
                    // 学習完了
                    StudyCompletedView(session: studySession) {
                        dismiss()
                    }
                }
                
                Spacer()
                
                // コントロール
                if currentFlashcard != nil {
                    StudyControlsView(
                        isFlipped: isFlipped,
                        canGoBack: currentIndex > 0,
                        onFlip: { flipCard() },
                        onCorrect: { handleAnswer(correct: true) },
                        onIncorrect: { handleAnswer(correct: false) },
                        onBack: { goToPreviousCard() }
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingProgress) {
            StudyProgressView(
                session: studySession,
                currentIndex: currentIndex,
                totalCount: flashcards.count,
                onSkip: { skipToEnd() }
            )
        }
    }
    
    private func flipCard() {
        withAnimation(.easeInOut(duration: 0.6)) {
            isFlipped.toggle()
        }
    }
    
    private func handleAnswer(correct: Bool) {
        guard let flashcard = currentFlashcard else { return }
        
        // 回答を記録
        if correct {
            flashcard.studyProgress.recordCorrect()
            studySession.recordCorrect()
        } else {
            flashcard.studyProgress.recordIncorrect()
            studySession.recordIncorrect()
        }
        
        // データを保存
        do {
            try modelContext.save()
        } catch {
            print("学習データの保存に失敗しました: \\(error)")
        }
        
        // 次のカードへ
        moveToNextCard()
    }
    
    private func moveToNextCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex += 1
            isFlipped = false
            dragOffset = .zero
        }
    }
    
    private func goToPreviousCard() {
        guard currentIndex > 0 else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex -= 1
            isFlipped = false
            dragOffset = .zero
        }
    }
    
    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let swipeThreshold: CGFloat = 100
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if value.translation.width > swipeThreshold {
                // 右スワイプ：正解
                if isFlipped {
                    handleAnswer(correct: true)
                } else {
                    goToPreviousCard()
                }
            } else if value.translation.width < -swipeThreshold {
                // 左スワイプ：不正解
                if isFlipped {
                    handleAnswer(correct: false)
                } else {
                    flipCard()
                }
            } else if value.translation.height < -swipeThreshold {
                // 上スワイプ：カードをめくる
                flipCard()
            }
            
            dragOffset = .zero
        }
    }
    
    private func skipToEnd() {
        currentIndex = flashcards.count
    }
}

struct StudyHeaderBar: View {
    let mode: StudyView.StudyMode
    let progress: Double
    let currentIndex: Int
    let totalCount: Int
    @Binding var showingProgress: Bool
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Button("終了", action: onClose)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(mode.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("\\(currentIndex + 1) / \\(totalCount)")
                    .font(.subheadline)
                    .foregroundColor(Color(mode.color))
            }
            
            Spacer()
            
            Button(action: { showingProgress = true }) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color(mode.color))
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .overlay(
            // プログレスバー
            VStack {
                Spacer()
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(mode.color)))
                    .scaleEffect(y: 2)
            }
        )
    }
}

struct StudyCardView: View {
    let flashcard: Flashcard
    @Binding var isFlipped: Bool
    @Binding var dragOffset: CGSize
    
    var body: some View {
        ZStack {
            // カード背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(height: 300)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // 表面（単語）
            VStack(spacing: 20) {
                Text("単語")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color(flashcard.category?.color ?? "AsaCoffeeBrown"))
                    .textCase(.uppercase)
                
                Text(flashcard.word)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Color("AsaDarkSlate"))
                    .multilineTextAlignment(.center)
                
                if let pronunciation = flashcard.pronunciation {
                    Text("/\\(pronunciation)/")
                        .font(.title3)
                        .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                        .italic()
                }
                
                HStack {
                    if flashcard.isBookmarked {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color("AsaMocha"))
                    }
                    
                    Text(flashcard.difficultyLevel.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color(flashcard.difficultyLevel.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(flashcard.difficultyLevel.color).opacity(0.1))
                        )
                }
            }
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            
            // 裏面（意味）
            VStack(spacing: 20) {
                Text("意味")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color(flashcard.category?.color ?? "AsaCoffeeBrown"))
                    .textCase(.uppercase)
                
                Text(flashcard.meaning)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(Color("AsaDarkSlate"))
                    .multilineTextAlignment(.center)
                
                if let example = flashcard.example {
                    VStack(spacing: 8) {
                        Text("例文")
                            .font(.caption.weight(.medium))
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
                            .textCase(.uppercase)
                        
                        Text(example)
                            .font(.body)
                            .foregroundColor(Color("AsaDarkSlate").opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : -180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .offset(dragOffset)
        .scaleEffect(1 - abs(dragOffset.width) * 0.0005)
        .rotationEffect(.degrees(dragOffset.width * 0.05))
        .padding(.horizontal, 20)
    }
}

struct StudyControlsView: View {
    let isFlipped: Bool
    let canGoBack: Bool
    let onFlip: () -> Void
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // ヒント
            if !isFlipped {
                Text("タップしてカードをめくる")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
            } else {
                Text("知っていましたか？")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaDarkSlate").opacity(0.6))
            }
            
            // メインコントロール
            if !isFlipped {
                HStack(spacing: 40) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left.circle")
                            .font(.title)
                            .foregroundColor(canGoBack ? Color("AsaDarkSlate") : Color("AsaDarkSlate").opacity(0.3))
                    }
                    .disabled(!canGoBack)
                    
                    Button(action: onFlip) {
                        VStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Text("めくる")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                    
                    Spacer()
                        .frame(width: 30)
                }
            } else {
                HStack(spacing: 30) {
                    Button(action: onIncorrect) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color("AsaMocha"))
                            
                            Text("わからない")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color("AsaMocha"))
                        }
                    }
                    
                    Button(action: onCorrect) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Text("知ってた")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                }
            }
        }
        .padding(.bottom, 40)
    }
}

struct StudyCompletedView: View {
    let session: StudySession
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text("学習完了！")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(Color("AsaDarkSlate"))
            
            VStack(spacing: 12) {
                Text("\\(session.totalAnswers)問中\\(session.correctAnswers)問正解")
                    .font(.title2)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("正解率: \\(Int(session.correctRate * 100))%")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            
            Button(action: onClose) {
                Text("完了")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AsaCoffeeBrown"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}

class StudySession: ObservableObject {
    @Published var correctAnswers = 0
    @Published var totalAnswers = 0
    @Published var startTime = Date()
    
    var correctRate: Double {
        guard totalAnswers > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalAnswers)
    }
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    func recordCorrect() {
        correctAnswers += 1
        totalAnswers += 1
    }
    
    func recordIncorrect() {
        totalAnswers += 1
    }
}

#Preview {
    let container = try! ModelContainer(for: Category.self, Flashcard.self, StudyProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let category = Category(name: "英語基礎", icon: "textbook", color: "AsaCoffeeBrown")
    let flashcards = [
        Flashcard(word: "Apple", meaning: "りんご", category: category),
        Flashcard(word: "Book", meaning: "本", category: category)
    ]
    
    return StudyView(flashcards: flashcards, studyMode: .category(category))
        .modelContainer(container)
}