// AsaApps/Apps/AsaBookTracker/Views/CurrentReadingView.swift
import SwiftUI
import AsaUIKit

/// 現在読書中の本を表示・管理するビュー
struct CurrentReadingView: View {
    @Bindable var viewModel: BookTrackerViewModel
    @State private var selectedBook: Book?
    @State private var showingSessionView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // コンテンツ
                if currentlyReadingBooks.isEmpty {
                    emptyStateView
                } else {
                    readingBooksView
                }
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSessionView) {
            if let book = selectedBook {
                ReadingSessionView(book: book, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentlyReadingBooks: [Book] {
        viewModel.books.filter { 
            $0.progress?.status == .reading || $0.progress?.status == .paused
        }
        .sorted { lhs, rhs in
            // 読書中を優先、その後は最近更新された順
            if lhs.progress?.status != rhs.progress?.status {
                return lhs.progress?.status == .reading
            }
            
            let lhsLastSession = lhs.sessions.max(by: { $0.startTime < $1.startTime })?.startTime ?? lhs.addedDate
            let rhsLastSession = rhs.sessions.max(by: { $0.startTime < $1.startTime })?.startTime ?? rhs.addedDate
            
            return lhsLastSession > rhsLastSession
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("現在の読書")
                    .font(.largeTitle.bold())
                    .foregroundColor(AsaColors.coffeeBrown)
                
                Text("\(currentlyReadingBooks.count)冊を読書中")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
            }
            
            Spacer()
            
            // 今日の読書時間
            todayReadingTimeView
        }
        .padding()
        .background(AsaColors.cardBackground)
        .shadow(color: AsaColors.darkSlate.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var todayReadingTimeView: some View {
        VStack(spacing: 4) {
            Text("今日の読書")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
            
            let todayMinutes = todayReadingMinutes
            Text("\(todayMinutes)分")
                .font(.headline.bold())
                .foregroundColor(AsaColors.coffeeBrown)
            
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AsaColors.softCream.opacity(0.5))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book")
                .font(.system(size: 80))
                .foregroundColor(AsaColors.mutedSage.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("読書中の本がありません")
                    .font(.title2.bold())
                    .foregroundColor(AsaColors.coffeeBrown)
                
                Text("ライブラリから本を選んで\n読書を始めましょう")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
            }
            
            // 最近追加された本（未読）
            if let recentBook = viewModel.books.filter({ $0.progress?.status == .notStarted }).first {
                VStack(spacing: 12) {
                    Text("最近追加した本")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                    
                    AsaCard {
                        HStack(spacing: 12) {
                            // カバー画像
                            Group {
                                if let imageData = recentBook.coverImageData,
                                   let image = UIImage(data: imageData) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AsaColors.softCream)
                                        .overlay(
                                            Image(systemName: "book.closed")
                                                .foregroundColor(AsaColors.coffeeBrown.opacity(0.7))
                                        )
                                }
                            }
                            .frame(width: 40, height: 55)
                            .cornerRadius(6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recentBook.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(AsaColors.coffeeBrown)
                                    .lineLimit(2)
                                
                                Text(recentBook.author)
                                    .font(.caption)
                                    .foregroundColor(AsaColors.mutedSage)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            AsaButton(
                                title: "読書開始",
                                action: { viewModel.startReading(recentBook) },
                                color: AsaColors.coffeeBrown
                            )
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    @ViewBuilder
    private var readingBooksView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(currentlyReadingBooks) { book in
                    CurrentReadingCardView(
                        book: book,
                        viewModel: viewModel,
                        onSessionStart: { selectedBook in
                            self.selectedBook = selectedBook
                            showingSessionView = true
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // タブバー分の余白
        }
    }
    
    // MARK: - Helper Methods
    
    private var todayReadingMinutes: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return viewModel.books
            .flatMap { $0.sessions }
            .filter { calendar.isDate($0.sessionDate, inSameDayAs: today) }
            .reduce(0) { $0 + $1.durationInMinutes }
    }
}

// MARK: - CurrentReadingCardView

struct CurrentReadingCardView: View {
    let book: Book
    @Bindable var viewModel: BookTrackerViewModel
    let onSessionStart: (Book) -> Void
    
    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                // 上部: 本の情報と状況
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
                                .fill(LinearGradient(
                                    colors: [AsaColors.softCream, AsaColors.mutedSage.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay(
                                    Image(systemName: "book")
                                        .font(.title)
                                        .foregroundColor(AsaColors.coffeeBrown.opacity(0.7))
                                )
                        }
                    }
                    .frame(width: 70, height: 95)
                    .cornerRadius(8)
                    .shadow(color: AsaColors.darkSlate.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // 本の情報
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AsaColors.coffeeBrown)
                            .lineLimit(2)
                        
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(AsaColors.darkSlate)
                            .lineLimit(1)
                        
                        // 読書状況バッジ
                        if let progress = book.progress {
                            HStack(spacing: 6) {
                                Image(systemName: progress.status.icon)
                                    .foregroundColor(Color(progress.status.color))
                                    .font(.caption)
                                
                                Text(progress.status.description)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Color(progress.status.color))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(progress.status.color).opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                
                // 進捗情報
                progressInfoView
                
                // アクションボタン
                actionButtonsView
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var progressInfoView: some View {
        VStack(spacing: 12) {
            // 進捗バーと数値
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let progress = book.progress {
                        Text("\(progress.currentPage) / \(book.totalPages)ページ")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AsaColors.darkSlate)
                    }
                    
                    Spacer()
                    
                    Text("\(book.completionPercentage)%完了")
                        .font(.subheadline.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                }
                
                ProgressView(value: book.completionRatio)
                    .progressViewStyle(CustomProgressViewStyle())
            }
            
            // 統計情報
            HStack(spacing: 20) {
                StatItem(
                    icon: "clock",
                    title: "読書時間",
                    value: "\(book.totalReadingMinutes)分"
                )
                
                StatItem(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "平均ペース",
                    value: String(format: "%.1fページ/日", book.averagePagesPerDay)
                )
                
                if let progress = book.progress,
                   let estimatedDate = progress.estimatedCompletionDate {
                    StatItem(
                        icon: "calendar",
                        title: "完了予想",
                        value: estimatedDate.formatted(.dateTime.month().day())
                    )
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            if let progress = book.progress {
                switch progress.status {
                case .reading:
                    HStack(spacing: 8) {
                        Button("一時停止") {
                            viewModel.pauseReading(book)
                        }
                        .font(.subheadline)
                        .foregroundColor(AsaColors.darkSlate)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AsaColors.softCream)
                        .cornerRadius(8)
                        
                        Button("読書記録") {
                            onSessionStart(book)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AsaColors.coffeeBrown)
                        .cornerRadius(8)
                        
                        Button("完了") {
                            viewModel.completeReading(book)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.green)
                        .cornerRadius(8)
                    }
                    
                case .paused:
                    HStack(spacing: 8) {
                        AsaButton(
                            title: "読書再開",
                            action: { viewModel.resumeReading(book) },
                            color: AsaColors.coffeeBrown
                        )
                        
                        Button("読書記録") {
                            onSessionStart(book)
                        }
                        .font(.subheadline)
                        .foregroundColor(AsaColors.coffeeBrown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AsaColors.softCream)
                        .cornerRadius(8)
                    }
                    
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - StatItem

struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(AsaColors.coffeeBrown)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(AsaColors.darkSlate.opacity(0.7))
        }
    }
}

// MARK: - Preview

#Preview {
    CurrentReadingView(viewModel: BookTrackerViewModel())
}