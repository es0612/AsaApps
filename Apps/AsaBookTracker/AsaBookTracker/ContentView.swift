// AsaApps/Apps/AsaBookTracker/ContentView.swift
import SwiftUI
import SwiftData
import AsaUIKit

/// メインのコンテンツビュー - タブベースナビゲーション
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BookTrackerViewModel()
    @State private var statisticsViewModel = StatisticsViewModel()
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 📚 ライブラリタブ
            BookListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("ライブラリ")
                }
                .tag(0)
            
            // 📖 現在読書中タブ
            CurrentReadingView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "book")
                    Text("読書中")
                }
                .tag(1)
            
            // 📊 統計タブ
            StatisticsView(viewModel: statisticsViewModel)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("統計")
                }
                .tag(2)
            
            // ⚙️ 設定タブ
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("設定")
                }
                .tag(3)
        }
        .background(AsaColors.softCream.opacity(0.1))
        .onAppear {
            setupViewModels()
        }
        .refreshable {
            await refreshData()
        }
    }
    
    // MARK: - Methods
    
    private func setupViewModels() {
        viewModel.setModelContext(modelContext)
        statisticsViewModel.setModelContext(modelContext, books: viewModel.books)
    }
    
    @MainActor
    private func refreshData() async {
        isRefreshing = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.refreshData()
            statisticsViewModel.setModelContext(modelContext, books: viewModel.books)
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
        isRefreshing = false
    }
}

// MARK: - BookListView

struct BookListView: View {
    @Bindable var viewModel: BookTrackerViewModel
    @State private var showingAddBook = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // フィルターとソート
                filterAndSortView
                
                // 本一覧
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredAndSortedBooks.isEmpty {
                    emptyStateView
                } else {
                    bookListView
                }
            }
            .background(AsaColors.softCream.opacity(0.1))
            .navigationBarHidden(true)
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView(viewModel: viewModel)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AsaBookTracker")
                    .font(.largeTitle.bold())
                    .foregroundColor(AsaColors.coffeeBrown)
                
                Text("読書進捗を管理")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
            }
            
            Spacer()
            
            AsaButton(
                title: "本を追加",
                action: { showingAddBook = true },
                color: AsaColors.coffeeBrown
            )
        }
        .padding()
        .background(AsaColors.cardBackground)
        .shadow(color: AsaColors.darkSlate.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var filterAndSortView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // ステータスフィルター
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.rawValue,
                        isSelected: viewModel.selectedStatus == status,
                        action: {
                            viewModel.selectedStatus = viewModel.selectedStatus == status ? nil : status
                        }
                    )
                }
                
                Divider()
                    .frame(height: 20)
                
                // ジャンルフィルター
                ForEach(BookGenre.allCases.prefix(5), id: \.self) { genre in
                    FilterChip(
                        title: genre.rawValue,
                        isSelected: viewModel.selectedGenre == genre,
                        action: {
                            viewModel.selectedGenre = viewModel.selectedGenre == genre ? nil : genre
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(AsaColors.cardBackground)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("本を読み込み中...")
                .foregroundColor(AsaColors.mutedSage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(AsaColors.mutedSage.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("本がありません")
                    .font(.headline)
                    .foregroundColor(AsaColors.coffeeBrown)
                
                Text("「本を追加」ボタンから\n最初の本を追加しましょう")
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
            }
            
            AsaButton(
                title: "本を追加",
                action: { showingAddBook = true },
                color: AsaColors.coffeeBrown
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var bookListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredAndSortedBooks) { book in
                    NavigationLink(destination: BookDetailView(book: book, viewModel: viewModel)) {
                        BookCardView(book: book, viewModel: viewModel)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // タブバー分の余白
        }
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : AsaColors.coffeeBrown)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? AsaColors.coffeeBrown : AsaColors.softCream
                )
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, ReadingProgress.self, ReadingSession.self, configurations: config)

    // サンプルデータを読み込む
    SampleBookData.loadSampleData(into: container.mainContext)

    return ContentView()
        .modelContainer(container)
}
