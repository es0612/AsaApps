import SwiftUI
import SwiftData

struct SessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyItem.aiPriorityScore, order: .reverse) private var studyItems: [StudyItem]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var recentSessions: [StudySession]
    @Query(sort: \LearningAnalytics.date, order: .reverse) private var analytics: [LearningAnalytics]
    @Query(sort: \StudyPlan.date, order: .reverse) private var plans: [StudyPlan]

    @State private var selectedItem: StudyItem?
    @State private var isSessionActive = false
    @State private var sessionMinutes = 25

    private var activeItems: [StudyItem] {
        studyItems.filter { !$0.isArchived && !$0.isCompleted }
    }

    private var todaySessions: [StudySession] {
        let today = Calendar.current.startOfDay(for: Date())
        return recentSessions.filter { session in
            Calendar.current.isDate(session.startedAt, inSameDayAs: today)
        }
    }

    private var todayTotalMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.actualMinutes }
    }

    private var todayAnalytics: LearningAnalytics? {
        let today = Calendar.current.startOfDay(for: Date())
        return analytics.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var todayPlan: StudyPlan? {
        plans.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            List {
                // 今日のサマリー
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("今日の学習")
                                .font(.headline)
                            Text("\(todaySessions.count)セッション")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(todayTotalMinutes)分")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("AsaCoffeeBrown"))
                    }
                    .padding(.vertical, 8)
                }

                // 学習項目選択
                Section("学習する項目を選択") {
                    if activeItems.isEmpty {
                        ContentUnavailableView(
                            "学習項目がありません",
                            systemImage: "book.closed",
                            description: Text("「学習項目」タブから追加してください")
                        )
                    } else {
                        ForEach(activeItems.prefix(5)) { item in
                            Button {
                                selectedItem = item
                                sessionMinutes = item.category.recommendedSessionMinutes
                            } label: {
                                HStack {
                                    Text(item.category.emoji)
                                        .font(.title2)

                                    VStack(alignment: .leading) {
                                        Text(item.title)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        HStack {
                                            Text(item.difficulty.displayName)
                                                .font(.caption)
                                                .foregroundStyle(item.difficulty.color)
                                            Text("・")
                                            Text("推奨: \(item.category.recommendedSessionMinutes)分")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if selectedItem?.id == item.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color("AsaCoffeeBrown"))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // セッション設定
                if selectedItem != nil {
                    Section("セッション設定") {
                        Stepper("学習時間: \(sessionMinutes)分", value: $sessionMinutes, in: 5...120, step: 5)

                        // プリセットボタン
                        HStack(spacing: 12) {
                            ForEach([15, 25, 45, 60], id: \.self) { minutes in
                                Button {
                                    sessionMinutes = minutes
                                } label: {
                                    Text("\(minutes)分")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(sessionMinutes == minutes ? Color("AsaCoffeeBrown") : Color(.systemGray6))
                                        .foregroundStyle(sessionMinutes == minutes ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 開始ボタン
                    Section {
                        Button {
                            startSession()
                        } label: {
                            HStack {
                                Spacer()
                                Label("学習を開始", systemImage: "play.fill")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color("AsaCoffeeBrown"))
                        .foregroundStyle(.white)
                    }
                }

                // 最近のセッション
                if !todaySessions.isEmpty {
                    Section("今日のセッション") {
                        ForEach(todaySessions.prefix(5)) { session in
                            SessionHistoryRow(session: session, studyItems: studyItems)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("学習セッション")
            .fullScreenCover(isPresented: $isSessionActive) {
                if let item = selectedItem {
                    ActiveSessionView(
                        studyItem: item,
                        plannedMinutes: sessionMinutes,
                        onComplete: { session in
                            handleSessionComplete(session: session, item: item)
                            isSessionActive = false
                        }
                    )
                }
            }
        }
    }

    private func startSession() {
        guard selectedItem != nil else { return }
        isSessionActive = true
    }

    private func handleSessionComplete(session: StudySession, item: StudyItem) {
        let engine = SpacedRepetitionEngine()
        engine.updateItemAfterSession(item: item, session: session)

        if let analytics = todayAnalytics {
            analytics.recordSession(session, category: item.category)
        } else {
            let newAnalytics = LearningAnalytics(date: Date())
            modelContext.insert(newAnalytics)
            newAnalytics.recordSession(session, category: item.category)
        }

        todayPlan?.markItemCompleted(item.id, minutes: session.actualMinutes, isMorning: session.isMorningSession)
        try? modelContext.save()
    }
}

// MARK: - Session History Row

struct SessionHistoryRow: View {
    let session: StudySession
    let studyItems: [StudyItem]

    private var studyItem: StudyItem? {
        studyItems.first { $0.id == session.studyItemId }
    }

    var body: some View {
        HStack {
            if let item = studyItem {
                Text(item.category.emoji)
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    Text(session.startedAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("📚")
                Text("不明な項目")
                    .font(.subheadline)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(session.actualMinutes)分")
                    .font(.subheadline)
                if session.isCompleted {
                    HStack(spacing: 2) {
                        ForEach(0..<session.focusLevel, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Active Session View

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let studyItem: StudyItem
    let plannedMinutes: Int
    let onComplete: (StudySession) -> Void

    @State private var timeRemaining: Int
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var showingCompleteSheet = false
    @State private var session: StudySession?

    init(studyItem: StudyItem, plannedMinutes: Int, onComplete: @escaping (StudySession) -> Void) {
        self.studyItem = studyItem
        self.plannedMinutes = plannedMinutes
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: plannedMinutes * 60)
    }

    private var progress: Double {
        let total = Double(plannedMinutes * 60)
        let elapsed = total - Double(timeRemaining)
        return elapsed / total
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 40) {
            // ヘッダー
            VStack(spacing: 8) {
                Text(studyItem.category.emoji)
                    .font(.system(size: 60))
                Text(studyItem.title)
                    .font(.title2.bold())
                Text(studyItem.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // タイマー
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color("AsaCoffeeBrown"),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack {
                    Text(timeString)
                        .font(.system(size: 60, weight: .bold, design: .monospaced))

                    if isPaused {
                        Text("一時停止中")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if isRunning {
                        Text("集中モード")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .frame(width: 280, height: 280)

            Spacer()

            // コントロール
            HStack(spacing: 40) {
                // 中止ボタン
                Button {
                    interruptSession()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red.opacity(0.8))
                }

                // 開始/一時停止ボタン
                Button {
                    if isRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color("AsaCoffeeBrown"))
                }

                // 完了ボタン
                Button {
                    showingCompleteSheet = true
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            createSession()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard isRunning, !isPaused else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // タイマー完了
                showingCompleteSheet = true
            }
        }
        .sheet(isPresented: $showingCompleteSheet) {
            SessionCompleteView(
                session: session,
                studyItem: studyItem,
                onSave: { focusLevel, comprehensionLevel, notes in
                    completeSession(focusLevel: focusLevel, comprehensionLevel: comprehensionLevel, notes: notes)
                }
            )
        }
    }

    private func createSession() {
        let newSession = StudySession(
            studyItemId: studyItem.id,
            plannedMinutes: plannedMinutes
        )
        modelContext.insert(newSession)
        session = newSession
    }

    private func startTimer() {
        isRunning = true
        isPaused = false
    }

    private func pauseTimer() {
        isPaused = true
    }

    private func interruptSession() {
        session?.interrupt()
        dismiss()
    }

    private func completeSession(focusLevel: Int, comprehensionLevel: Int, notes: String?) {
        session?.complete(focusLevel: focusLevel, comprehensionLevel: comprehensionLevel, notes: notes)

        // StudyItemの統計更新
        if let session = session {
            studyItem.recordSession(durationMinutes: session.actualMinutes, quality: session.qualityScore)
            onComplete(session)
        }

        dismiss()
    }
}

// MARK: - Session Complete View

struct SessionCompleteView: View {
    @Environment(\.dismiss) private var dismiss

    let session: StudySession?
    let studyItem: StudyItem
    let onSave: (Int, Int, String?) -> Void

    @State private var focusLevel = 3
    @State private var comprehensionLevel = 3
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 60))
                        Text("セッション完了！")
                            .font(.title2.bold())
                        Text(studyItem.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)

                Section("集中度を評価") {
                    RatingPicker(value: $focusLevel, label: "集中度")
                }

                Section("理解度を評価") {
                    RatingPicker(value: $comprehensionLevel, label: "理解度")
                }

                Section("メモ（任意）") {
                    TextField("学習メモ", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("セッション評価")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(focusLevel, comprehensionLevel, notes.isEmpty ? nil : notes)
                    }
                }
            }
        }
    }
}

// MARK: - Rating Picker

struct RatingPicker: View {
    @Binding var value: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        value = rating
                    } label: {
                        Image(systemName: rating <= value ? "star.fill" : "star")
                            .font(.title)
                            .foregroundStyle(rating <= value ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(ratingDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var ratingDescription: String {
        switch value {
        case 1: return "全く\(label == "集中度" ? "集中できなかった" : "理解できなかった")"
        case 2: return "あまり\(label == "集中度" ? "集中できなかった" : "理解できなかった")"
        case 3: return "普通"
        case 4: return "よく\(label == "集中度" ? "集中できた" : "理解できた")"
        case 5: return "非常に\(label == "集中度" ? "集中できた" : "理解できた")"
        default: return ""
        }
    }
}

#Preview {
    SessionView()
        .modelContainer(for: [
            StudyItem.self,
            StudySession.self,
            StudyPlan.self,
            LearningAnalytics.self,
            UserLearningProfile.self
        ], inMemory: true)
}
