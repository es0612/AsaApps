import SwiftUI
import CoreData

struct HistoryListView: View {
    @StateObject private var historyService = WeatherHistoryService.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingSettings = false
    @State private var showingDatePicker = false
    @State private var selectedDateRange: DateRange = .week
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    
    enum DateRange: String, CaseIterable {
        case today = "今日"
        case week = "1週間"
        case month = "1ヶ月"
        case custom = "カスタム"
    }
    
    var filteredRecords: [WeatherRecord] {
        let endDate = Date()
        let startDate: Date
        
        switch selectedDateRange {
        case .today:
            startDate = Calendar.current.startOfDay(for: endDate)
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .custom:
            startDate = customStartDate
        }
        
        return historyService.loadRecords(from: startDate, to: endDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 期間選択セクション
                periodSelectionSection
                
                // 現在の天気カード（最新データ）
                if let currentWeather = historyService.currentWeatherData {
                    currentWeatherCard(currentWeather)
                        .padding(.horizontal)
                        .padding(.top)
                }
                
                // 履歴リスト
                historyListSection
            }
            .navigationTitle("天気履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await historyService.fetchAndSaveCurrentWeather()
                        }
                    } label: {
                        Image(systemName: historyService.isLoading ? "arrow.clockwise" : "arrow.clockwise.circle.fill")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .rotationEffect(.degrees(historyService.isLoading ? 360 : 0))
                            .animation(.linear(duration: 1).repeatWhileTrue(historyService.isLoading), value: historyService.isLoading)
                    }
                    .disabled(historyService.isLoading)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingDatePicker) {
            DateRangePickerView(
                startDate: $customStartDate,
                endDate: $customEndDate,
                isPresented: $showingDatePicker
            )
        }
        .onAppear {
            historyService.loadRecentRecords()
        }
        .alert("エラー", isPresented: .constant(historyService.errorMessage != nil)) {
            Button("OK") {
                historyService.errorMessage = nil
            }
        } message: {
            Text(historyService.errorMessage ?? "")
        }
    }
    
    // MARK: - Period Selection Section
    private var periodSelectionSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Button {
                        selectedDateRange = range
                        if range == .custom {
                            showingDatePicker = true
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(selectedDateRange == range ? .white : Color("AsaCoffeeBrown"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedDateRange == range ? Color("AsaCoffeeBrown") : Color("AsaSoftCream"))
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Current Weather Card
    private func currentWeatherCard(_ weatherData: WeatherData) -> some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("現在の天気")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(weatherData.name)
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let lastUpdate = historyService.lastUpdateDate {
                            Text("更新: \(lastUpdate, formatter: timeFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Image(systemName: weatherData.weatherIconName)
                            .font(.title)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(weatherData.temperatureString)
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text(weatherData.weatherDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(weatherData.feelsLikeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(weatherData.humidityString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(weatherData.windSpeedString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - History List Section
    private var historyListSection: some View {
        Group {
            if filteredRecords.isEmpty {
                emptyStateView
            } else {
                List(filteredRecords, id: \.objectID) { record in
                    NavigationLink(destination: WeatherDetailView(record: record)) {
                        HistoryRowView(record: record)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 2)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await historyService.fetchAndSaveCurrentWeather()
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.rain")
                .font(.system(size: 60))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 8) {
                Text("履歴がありません")
                    .font(.title2.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("右上の更新ボタンを押して\n天気データを取得してください")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task {
                    await historyService.fetchAndSaveCurrentWeather()
                }
            } label: {
                Text("天気を取得")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("AsaCoffeeBrown"))
                    )
            }
            .disabled(historyService.isLoading)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let record: WeatherRecord
    
    var body: some View {
        AsaCard {
            HStack(spacing: 12) {
                // 天気アイコン
                Image(systemName: record.weatherIconName)
                    .font(.title2)
                    .foregroundColor(Color(record.weatherColor))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(record.weatherColor).opacity(0.1))
                    )
                
                // 天気情報
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.locationName ?? "不明な場所")
                            .font(.headline)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Spacer()
                        
                        Text(record.temperatureString)
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    HStack {
                        Text(record.weatherDescription ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(record.shortDisplayDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var historyService = WeatherHistoryService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("データベース情報") {
                    let stats = historyService.getDatabaseStatistics()
                    
                    HStack {
                        Text("総レコード数")
                        Spacer()
                        Text("\(stats.totalRecords)件")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("今日のレコード数")
                        Spacer()
                        Text("\(stats.todaysRecords)件")
                            .foregroundColor(.secondary)
                    }
                    
                    if let oldest = stats.oldestRecord {
                        HStack {
                            Text("最古のレコード")
                            Spacer()
                            Text(oldest, formatter: dateFormatter)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let newest = stats.newestRecord {
                        HStack {
                            Text("最新のレコード")
                            Spacer()
                            Text(newest, formatter: dateFormatter)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("データ管理") {
                    Button("古いデータを削除（90日以前）") {
                        historyService.cleanupOldRecords()
                    }
                    .foregroundColor(.red)
                }
                
                #if DEBUG
                Section("開発者向け") {
                    Button("テストデータを生成") {
                        CoreDataStack.shared.seedTestData()
                        historyService.loadRecentRecords()
                    }
                    
                    Button("全データを削除") {
                        CoreDataStack.shared.deleteAllData()
                        historyService.loadRecentRecords()
                    }
                    .foregroundColor(.red)
                }
                #endif
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Date Range Picker View
struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                
                DatePicker("終了日", selection: $endDate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
            }
            .padding()
            .navigationTitle("期間を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Animation Extension
extension Animation {
    func repeatWhileTrue(_ condition: Bool) -> Animation {
        condition ? self.repeatForever(autoreverses: false) : self
    }
}

// MARK: - Formatters
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter
}()

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter
}()

// MARK: - AsaCard (共有コンポーネント)
struct AsaCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            )
    }
}