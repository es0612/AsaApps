// AsaApps/Apps/AsaBookTracker/Views/BookDetailView.swift
import SwiftUI
import AsaUIKit

/// 本の詳細情報と進捗管理ビュー
struct BookDetailView: View {
    let book: Book
    @Bindable var viewModel: BookTrackerViewModel
    @State private var isEditingProgress = false
    @State private var newPageCount = ""
    @State private var showingEditBook = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー情報
                    bookHeaderSection
                    
                    // 進捗セクション
                    progressSection
                    
                    // 読書セッション履歴
                    sessionsSection
                    
                    // レビューセクション
                    if book.progress?.status == .completed {
                        reviewSection
                    }
                    
                    // 統計セクション
                    statisticsSection
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("編集") {
                        showingEditBook = true
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
        .sheet(isPresented: $showingEditBook) {
            EditBookView(book: book, viewModel: viewModel)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var bookHeaderSection: some View {
        AsaCard {
            HStack(spacing: 16) {
                // カバー画像
                Group {
                    if let imageData = book.coverImageData,
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [AsaColors.softCream, AsaColors.mutedSage.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                Image(systemName: "book.closed")
                                    .font(.system(size: 40))
                                    .foregroundColor(AsaColors.coffeeBrown.opacity(0.7))
                            )
                    }
                }
                .frame(width: 100, height: 140)
                .cornerRadius(12)
                .shadow(color: AsaColors.darkSlate.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // 本の情報
                VStack(alignment: .leading, spacing: 12) {
                    Text(book.title)
                        .font(.title2.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                        .lineLimit(3)
                    
                    Text(book.author)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    HStack(spacing: 16) {
                        InfoItem(icon: "book", text: "\(book.totalPages)ページ")
                        
                        if let genre = BookGenre.allCases.first(where: { $0.rawValue == book.genre }) {
                            InfoItem(icon: "tag", text: genre.rawValue)
                        }
                    }
                    
                    if let isbn = book.isbn {
                        InfoItem(icon: "barcode", text: "ISBN: \(isbn)")
                    }
                    
                    Spacer()
                    
                    // 読書状況バッジ
                    if let progress = book.progress {
                        HStack(spacing: 8) {
                            Image(systemName: progress.status.icon)
                                .foregroundColor(Color(progress.status.color))
                            
                            Text(progress.status.description)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color(progress.status.color))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(progress.status.color).opacity(0.1))
                        .cornerRadius(16)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var progressSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("📖 読書進捗")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    Spacer()
                    
                    Button("進捗更新") {
                        isEditingProgress.toggle()
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(AsaColors.coffeeBrown)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AsaColors.softCream)
                    .cornerRadius(8)
                }
                
                if let progress = book.progress {
                    // 進捗表示
                    VStack(spacing: 12) {
                        // 進捗バー
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(progress.currentPage) / \(book.totalPages)ページ")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(AsaColors.darkSlate)
                                
                                Spacer()
                                
                                Text("\(book.completionPercentage)%")
                                    .font(.subheadline.bold())
                                    .foregroundColor(AsaColors.coffeeBrown)
                            }
                            
                            ProgressView(value: book.completionRatio)
                                .progressViewStyle(CustomProgressViewStyle())
                        }
                        
                        // 読書日数と予想完了日
                        HStack(spacing: 20) {
                            if let readingDays = book.readingDays {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("読書日数")
                                        .font(.caption)
                                        .foregroundColor(AsaColors.mutedSage)
                                    Text("\(readingDays)日")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(AsaColors.darkSlate)
                                }
                            }
                            
                            if let estimatedDate = progress.estimatedCompletionDate {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("完了予想日")
                                        .font(.caption)
                                        .foregroundColor(AsaColors.mutedSage)
                                    Text(estimatedDate, style: .date)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(AsaColors.darkSlate)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // 進捗更新フォーム
                        if isEditingProgress {
                            progressUpdateForm
                        }
                        
                        // アクションボタン
                        progressActionButtons(progress: progress)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var progressUpdateForm: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack {
                Text("現在のページ:")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.darkSlate)
                
                TextField("ページ数", text: $newPageCount)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                
                AsaButton(
                    title: "更新",
                    action: updateProgress,
                    color: AsaColors.coffeeBrown,
                    isEnabled: !newPageCount.isEmpty
                )
            }
        }
        .onAppear {
            newPageCount = String(book.progress?.currentPage ?? 0)
        }
    }
    
    @ViewBuilder
    private func progressActionButtons(progress: ReadingProgress) -> some View {
        HStack(spacing: 12) {
            switch progress.status {
            case .notStarted:
                AsaButton(
                    title: "読書開始",
                    action: { viewModel.startReading(book) },
                    color: AsaColors.coffeeBrown
                )
                
            case .reading:
                HStack(spacing: 8) {
                    Button("一時停止") {
                        viewModel.pauseReading(book)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AsaColors.softCream)
                    .cornerRadius(10)
                    
                    AsaButton(
                        title: "完了",
                        action: { viewModel.completeReading(book) },
                        color: .green
                    )
                }
                
            case .paused:
                HStack(spacing: 8) {
                    AsaButton(
                        title: "再開",
                        action: { viewModel.resumeReading(book) },
                        color: AsaColors.coffeeBrown
                    )
                    
                    AsaButton(
                        title: "完了",
                        action: { viewModel.completeReading(book) },
                        color: .green
                    )
                }
                
            case .completed:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("読了完了")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if let completedDate = progress.completedDate {
                        Text("完了日: \(completedDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var sessionsSection: some View {
        if !book.sessions.isEmpty {
            AsaCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("📊 読書セッション履歴")
                        .font(.headline)
                        .foregroundColor(AsaColors.coffeeBrown)
                    
                    ForEach(book.sessions.sorted(by: { $0.startTime > $1.startTime }).prefix(5), id: \.id) { session in
                        SessionRowView(session: session)
                    }
                    
                    if book.sessions.count > 5 {
                        Text("他\(book.sessions.count - 5)セッション")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var reviewSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("⭐ レビュー")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                
                if let progress = book.progress,
                   let rating = progress.rating {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.orange)
                                .font(.title2)
                        }
                        Spacer()
                    }
                }
                
                if let review = book.progress?.review, !review.isEmpty {
                    Text(review)
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                        .padding()
                        .background(AsaColors.softCream.opacity(0.5))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("📈 統計情報")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                
                let stats = [
                    ("総読書時間", "\(book.totalReadingMinutes)分"),
                    ("セッション数", "\(book.sessions.count)回"),
                    ("平均読書速度", String(format: "%.1fページ/日", book.averagePagesPerDay)),
                    ("追加日", DateFormatter.shortStyle.string(from: book.addedDate))
                ]
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(stats, id: \.0) { title, value in
                        VStack(spacing: 4) {
                            Text(value)
                                .font(.headline.bold())
                                .foregroundColor(AsaColors.coffeeBrown)
                            
                            Text(title)
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AsaColors.softCream.opacity(0.5))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func updateProgress() {
        guard let pageCount = Int(newPageCount) else { return }
        viewModel.updateProgress(book, to: pageCount)
        isEditingProgress = false
    }
}

// MARK: - Helper Views

struct InfoItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
            
            Text(text)
                .font(.caption)
                .foregroundColor(AsaColors.darkSlate)
        }
    }
}

struct SessionRowView: View {
    let session: ReadingSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
                
                Text("\(session.pagesRead)ページ読了")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.formattedDuration)
                    .font(.caption.weight(.medium))
                    .foregroundColor(AsaColors.coffeeBrown)
                
                if let mood = session.mood {
                    Text(mood.icon)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortStyle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}