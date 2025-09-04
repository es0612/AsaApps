// AsaApps/Apps/AsaBookTracker/Views/Components/BookCardView.swift
import SwiftUI
import AsaUIKit

/// 本の情報を表示するカードコンポーネント
struct BookCardView: View {
    let book: Book
    let viewModel: BookTrackerViewModel
    
    var body: some View {
        AsaCard {
            VStack(spacing: 0) {
                // 上部: 本の基本情報
                HStack(spacing: 12) {
                    // カバー画像またはプレースホルダー
                    coverImageView
                    
                    // 本の詳細情報
                    VStack(alignment: .leading, spacing: 8) {
                        // タイトル
                        Text(book.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(AsaColors.coffeeBrown)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        // 著者
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(AsaColors.darkSlate)
                            .lineLimit(1)
                        
                        // ジャンル
                        HStack(spacing: 4) {
                            if let genre = BookGenre.allCases.first(where: { $0.rawValue == book.genre }) {
                                Text(genre.icon)
                                    .font(.caption)
                                Text(genre.rawValue)
                                    .font(.caption)
                                    .foregroundColor(AsaColors.mutedSage)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AsaColors.softCream)
                                    .cornerRadius(8)
                            }
                        }
                        
                        Spacer()
                        
                        // 読書状況
                        readingStatusView
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 12)
                
                // 進捗バーとアクション
                progressSection
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var coverImageView: some View {
        Group {
            if let imageData = book.coverImageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // プレースホルダー画像
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [AsaColors.softCream, AsaColors.mutedSage.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "book.closed")
                                .font(.title2)
                                .foregroundColor(AsaColors.coffeeBrown.opacity(0.7))
                            
                            Text("\(book.totalPages)")
                                .font(.caption.bold())
                                .foregroundColor(AsaColors.darkSlate.opacity(0.7))
                        }
                    )
            }
        }
        .frame(width: 60, height: 80)
        .cornerRadius(8)
        .shadow(color: AsaColors.darkSlate.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var readingStatusView: some View {
        if let progress = book.progress {
            HStack(spacing: 8) {
                Image(systemName: progress.status.icon)
                    .foregroundColor(Color(progress.status.color))
                    .font(.caption.weight(.medium))
                
                Text(progress.status.description)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color(progress.status.color))
                
                if progress.status == .completed,
                   let rating = progress.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.orange)
                                .font(.caption2)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(progress.status.color).opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var progressSection: some View {
        VStack(spacing: 12) {
            // 進捗情報
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("進捗:")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                        
                        if let progress = book.progress {
                            Text("\(progress.currentPage) / \(book.totalPages)ページ")
                                .font(.caption.weight(.medium))
                                .foregroundColor(AsaColors.darkSlate)
                        }
                    }
                    
                    // 完了率
                    Text("\(book.completionPercentage)%完了")
                        .font(.caption2)
                        .foregroundColor(AsaColors.coffeeBrown)
                }
                
                Spacer()
                
                // 読書時間
                if book.totalReadingMinutes > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("読書時間")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                        
                        Text("\(book.totalReadingMinutes)分")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AsaColors.darkSlate)
                    }
                }
            }
            
            // 進捗バー
            ProgressView(value: book.completionRatio)
                .progressViewStyle(CustomProgressViewStyle())
            
            // クイックアクション
            if let progress = book.progress {
                quickActionButtons(progress: progress)
            }
        }
    }
    
    @ViewBuilder
    private func quickActionButtons(progress: ReadingProgress) -> some View {
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
                    .font(.caption.weight(.medium))
                    .foregroundColor(AsaColors.darkSlate)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AsaColors.softCream)
                    .cornerRadius(8)
                    
                    Button("進捗更新") {
                        // 進捗更新のアクション
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AsaColors.coffeeBrown)
                    .cornerRadius(8)
                }
                
            case .paused:
                AsaButton(
                    title: "読書再開",
                    action: { viewModel.resumeReading(book) },
                    color: AsaColors.coffeeBrown
                )
                
            case .completed:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("読了完了")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if let completedDate = progress.completedDate {
                        Text(completedDate, style: .date)
                            .font(.caption2)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }
            }
        }
    }
}

// MARK: - Custom Progress View Style

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 4)
                    .fill(AsaColors.softCream)
                    .frame(height: 8)
                
                // 進捗
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [AsaColors.coffeeBrown, AsaColors.mocha],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: 8)
                    .animation(.easeInOut(duration: 0.3), value: configuration.fractionCompleted)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview

#Preview {
    let sampleBook = Book(
        title: "サンプル本のタイトル",
        author: "著者名",
        totalPages: 300,
        genre: BookGenre.fiction.rawValue
    )
    
    // サンプル進捗を追加
    let progress = ReadingProgress(currentPage: 120, status: .reading)
    sampleBook.progress = progress
    
    return VStack {
        BookCardView(book: sampleBook, viewModel: BookTrackerViewModel())
            .padding()
    }
    .background(AsaColors.softCream.opacity(0.1))
}