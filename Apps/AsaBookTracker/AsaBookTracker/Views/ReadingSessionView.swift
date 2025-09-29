// AsaApps/Apps/AsaBookTracker/Views/ReadingSessionView.swift
import SwiftUI
import AsaUIKit

/// 読書セッションの記録・管理ビュー
struct ReadingSessionView: View {
    let book: Book
    @Bindable var viewModel: BookTrackerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSessionActive = false
    @State private var currentSession: ReadingSession?
    @State private var startPage = ""
    @State private var endPage = ""
    @State private var sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var elapsedTime: TimeInterval = 0
    @State private var startTime = Date()
    
    // セッション評価
    @State private var selectedMood: ReadingMood?
    @State private var concentration: Double = 3.0
    @State private var sessionNotes = ""
    @State private var readingLocation = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 本の情報カード
                    bookInfoCard
                    
                    // 現在の進捗
                    progressCard
                    
                    // セッション記録エリア
                    if isSessionActive {
                        activeSessionCard
                    } else {
                        sessionStartCard
                    }
                    
                    // セッション評価（セッション終了後）
                    if !isSessionActive && currentSession?.endTime != nil {
                        sessionEvaluationCard
                    }
                    
                    // 過去のセッション履歴
                    sessionHistoryCard
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationTitle("読書セッション")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        if isSessionActive {
                            endCurrentSession()
                        }
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
        .onReceive(sessionTimer) { _ in
            if isSessionActive {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
        .onAppear {
            initializeSession()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var bookInfoCard: some View {
        AsaCard {
            HStack(spacing: 12) {
                // カバー画像
                Group {
                    if let imageData = book.coverImageData,
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AsaColors.softCream)
                            .overlay(
                                Image(systemName: "book")
                                    .font(.title)
                                    .foregroundColor(AsaColors.coffeeBrown.opacity(0.7))
                            )
                    }
                }
                .frame(width: 60, height: 80)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(AsaColors.coffeeBrown)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                        
                        Text("\(book.totalPages)ページ")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var progressCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("📖 現在の進捗")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                
                if let progress = book.progress {
                    HStack {
                        Text("\(progress.currentPage) / \(book.totalPages)ページ")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AsaColors.darkSlate)
                        
                        Spacer()
                        
                        Text("\(book.completionPercentage)%完了")
                            .font(.subheadline.bold())
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                    
                    ProgressView(value: book.completionRatio)
                        .progressViewStyle(CustomProgressViewStyle())
                    
                    // 統計情報
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("読書時間")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Text("\(book.totalReadingMinutes)分")
                                .font(.caption.weight(.medium))
                                .foregroundColor(AsaColors.darkSlate)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("セッション数")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                            Text("\(book.sessions.count)回")
                                .font(.caption.weight(.medium))
                                .foregroundColor(AsaColors.darkSlate)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var sessionStartCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("📝 新しいセッションを開始")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                
                // 開始ページ入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("開始ページ")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AsaColors.darkSlate)
                    
                    TextField("ページ番号", text: $startPage)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                // 読書場所（任意）
                VStack(alignment: .leading, spacing: 8) {
                    Text("読書場所（任意）")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AsaColors.darkSlate)
                    
                    TextField("例: 自宅、カフェ、電車内", text: $readingLocation)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // セッション開始ボタン
                AsaButton(
                    title: "読書セッション開始",
                    action: startSession,
                    color: AsaColors.coffeeBrown,
                    isEnabled: !startPage.isEmpty && Int(startPage) != nil
                )
            }
        }
    }
    
    @ViewBuilder
    private var activeSessionCard: some View {
        AsaCard {
            VStack(spacing: 16) {
                // タイマー表示
                VStack(spacing: 8) {
                    Text("⏱️ 読書中")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    Text(formatTime(elapsedTime))
                        .font(.largeTitle.bold())
                        .foregroundColor(AsaColors.darkSlate)
                        .monospacedDigit()
                    
                    if let session = currentSession {
                        Text("開始: \(session.startPage)ページから")
                            .font(.subheadline)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
                .padding()
                .background(AsaColors.softCream.opacity(0.3))
                .cornerRadius(16)
                
                // 現在のページ入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("現在読んでいるページ")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AsaColors.darkSlate)
                    
                    TextField("ページ番号", text: $endPage)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                // セッション終了ボタン
                AsaButton(
                    title: "セッション終了",
                    action: endCurrentSession,
                    color: .red
                )
            }
        }
    }
    
    @ViewBuilder
    private var sessionEvaluationCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("✨ セッション評価")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                
                // 気分選択
                VStack(alignment: .leading, spacing: 12) {
                    Text("読書中の気分")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AsaColors.darkSlate)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(ReadingMood.allCases, id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                action: { selectedMood = mood }
                            )
                        }
                    }
                }
                
                // 集中度スライダー
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("集中度")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AsaColors.darkSlate)
                        
                        Spacer()
                        
                        Text("\(Int(concentration))/5")
                            .font(.subheadline.bold())
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                    
                    Slider(value: $concentration, in: 1...5, step: 1)
                        .tint(AsaColors.coffeeBrown)
                }
                
                // メモ入力
                VStack(alignment: .leading, spacing: 8) {
                    Text("メモ・感想")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AsaColors.darkSlate)
                    
                    TextEditor(text: $sessionNotes)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(AsaColors.softCream.opacity(0.5))
                        .cornerRadius(8)
                }
                
                // 保存ボタン
                AsaButton(
                    title: "評価を保存",
                    action: saveSessionEvaluation,
                    color: AsaColors.coffeeBrown
                )
            }
        }
    }
    
    @ViewBuilder
    private var sessionHistoryCard: some View {
        let recentSessions = book.sessions
            .sorted(by: { $0.startTime > $1.startTime })
            .prefix(5)
        
        if !recentSessions.isEmpty {
            AsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("📚 最近のセッション履歴")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    ForEach(Array(recentSessions), id: \.id) { session in
                        SessionHistoryRow(session: session)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeSession() {
        if let progress = book.progress {
            startPage = String(progress.currentPage)
            endPage = String(progress.currentPage)
        }
    }
    
    private func startSession() {
        guard let startPageNum = Int(startPage) else { return }
        
        isSessionActive = true
        startTime = Date()
        elapsedTime = 0
        
        currentSession = viewModel.startReadingSession(book, at: startPageNum)
        currentSession?.location = readingLocation.isEmpty ? nil : readingLocation
    }
    
    private func endCurrentSession() {
        guard let session = currentSession,
              let endPageNum = Int(endPage) else { return }
        
        isSessionActive = false
        sessionTimer.upstream.connect().cancel()
        
        viewModel.endReadingSession(
            session,
            at: endPageNum,
            mood: selectedMood,
            concentration: Int(concentration),
            notes: sessionNotes.isEmpty ? nil : sessionNotes
        )
    }
    
    private func saveSessionEvaluation() {
        guard let session = currentSession else { return }
        
        session.mood = selectedMood
        session.concentration = Int(concentration)
        session.notes = sessionNotes.isEmpty ? nil : sessionNotes
        
        viewModel.updateBook(book)
        
        // 評価後にセッションをリセット
        currentSession = nil
        selectedMood = nil
        concentration = 3.0
        sessionNotes = ""
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - MoodButton

struct MoodButton: View {
    let mood: ReadingMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.icon)
                    .font(.title2)
                
                Text(mood.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : AsaColors.darkSlate)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ? 
                Color(mood.color) : 
                AsaColors.softCream.opacity(0.5)
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color(mood.color) : AsaColors.mutedSage.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SessionHistoryRow

struct SessionHistoryRow: View {
    let session: ReadingSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startTime, style: .date)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AsaColors.coffeeBrown)
                
                Text("\(session.pagesRead)ページ読了")
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate)
                
                if let location = session.location {
                    Text("📍 \(location)")
                        .font(.caption2)
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.formattedDuration)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                
                if let mood = session.mood {
                    Text(mood.icon)
                        .font(.caption)
                }
                
                if let concentration = session.concentration {
                    HStack(spacing: 1) {
                        ForEach(1...5, id: \.self) { level in
                            Image(systemName: level <= concentration ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(level <= concentration ? .orange : AsaColors.mutedSage)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    let sampleBook = Book(
        title: "サンプル読書",
        author: "著者名",
        totalPages: 300,
        genre: BookGenre.fiction.rawValue
    )
    
    return ReadingSessionView(book: sampleBook, viewModel: BookTrackerViewModel())
}