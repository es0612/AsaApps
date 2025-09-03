import SwiftUI

struct ContentView: View {
    @StateObject private var historyService = WeatherHistoryService.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            // 履歴タブ
            HistoryListView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("履歴")
                }
                .tag(0)
            
            // グラフタブ
            ChartView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("グラフ")
                }
                .tag(1)
            
            // 統計タブ
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("統計")
                }
                .tag(2)
        }
        .accentColor(Color("AsaCoffeeBrown"))
        .onAppear {
            // タブビューが表示された時の処理
            setupInitialData()
        }
    }
    
    // MARK: - Initial Setup
    private func setupInitialData() {
        // 履歴データを読み込み
        historyService.loadRecentRecords()
        
        // 最後の更新から24時間以上経過している場合、自動更新
        if shouldAutoUpdate() {
            Task {
                await historyService.fetchAndSaveCurrentWeather()
            }
        }
    }
    
    private func shouldAutoUpdate() -> Bool {
        guard let lastUpdate = historyService.lastUpdateDate else { return true }
        let hoursSinceLastUpdate = Date().timeIntervalSince(lastUpdate) / 3600
        return hoursSinceLastUpdate > 24
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    @StateObject private var historyService = WeatherHistoryService.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 概要統計カード
                    overviewCard
                    
                    // 天気統計カード
                    weatherStatsCard
                    
                    // 月別統計カード
                    monthlyStatsCard
                    
                    // データベース情報カード
                    databaseInfoCard
                }
                .padding()
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await historyService.fetchAndSaveCurrentWeather()
            }
        }
        .onAppear {
            historyService.loadRecentRecords(limit: 200)
        }
    }
    
    // MARK: - Overview Card
    private var overviewCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("概要統計")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                let stats = historyService.getDatabaseStatistics()
                let tempExtremes = historyService.getTemperatureExtremes(days: 30)
                let avgTemp = historyService.getAverageTemperature(days: 30)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    OverviewStatItem(
                        title: "総レコード数",
                        value: "\(stats.totalRecords)",
                        subtitle: "件",
                        color: Color("AsaCoffeeBrown")
                    )
                    
                    OverviewStatItem(
                        title: "今日のレコード",
                        value: "\(stats.todaysRecords)",
                        subtitle: "件",
                        color: .blue
                    )
                    
                    OverviewStatItem(
                        title: "30日平均気温",
                        value: String(format: "%.1f", avgTemp),
                        subtitle: "°C",
                        color: .orange
                    )
                    
                    if let extremes = tempExtremes {
                        OverviewStatItem(
                            title: "気温範囲",
                            value: String(format: "%.0f~%.0f", extremes.min, extremes.max),
                            subtitle: "°C",
                            color: .green
                        )
                    }
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Weather Stats Card
    private var weatherStatsCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("天気統計（30日間）")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                let weatherStats = historyService.getWeatherStatistics(days: 30)
                
                if weatherStats.isEmpty {
                    Text("データがありません")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(weatherStats.sorted(by: { $0.value > $1.value }), id: \.key) { weather, count in
                            WeatherStatRow(
                                weatherType: weather,
                                count: count,
                                total: weatherStats.values.reduce(0, +)
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Monthly Stats Card
    private var monthlyStatsCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("月別データ")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                VStack(spacing: 12) {
                    MonthlyStatRow(period: "今月", days: 30)
                    MonthlyStatRow(period: "先月", days: 60, offset: 30)
                    MonthlyStatRow(period: "3ヶ月前", days: 90, offset: 60)
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Database Info Card
    private var databaseInfoCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("データベース情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                let stats = historyService.getDatabaseStatistics()
                
                VStack(spacing: 8) {
                    if let oldest = stats.oldestRecord {
                        DatabaseInfoRow(
                            title: "最古のレコード",
                            value: DateFormatter.medium.string(from: oldest)
                        )
                    }
                    
                    if let newest = stats.newestRecord {
                        DatabaseInfoRow(
                            title: "最新のレコード",
                            value: DateFormatter.medium.string(from: newest)
                        )
                    }
                    
                    if let lastUpdate = historyService.lastUpdateDate {
                        DatabaseInfoRow(
                            title: "最終更新",
                            value: DateFormatter.relative.string(from: lastUpdate)
                        )
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Supporting Views
struct OverviewStatItem: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeatherStatRow: View {
    let weatherType: String
    let count: Int
    let total: Int
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) * 100 : 0
    }
    
    private var weatherIcon: String {
        switch weatherType.lowercased() {
        case "clear": return "sun.max.fill"
        case "clouds": return "cloud.fill"
        case "rain": return "cloud.rain.fill"
        case "snow": return "cloud.snow.fill"
        case "thunderstorm": return "cloud.bolt.fill"
        default: return "cloud.fill"
        }
    }
    
    private var weatherColor: Color {
        switch weatherType.lowercased() {
        case "clear": return .yellow
        case "clouds": return Color("AsaMutedSage")
        case "rain": return .blue
        case "snow": return .cyan
        case "thunderstorm": return .purple
        default: return Color("AsaCoffeeBrown")
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: weatherIcon)
                .foregroundColor(weatherColor)
                .frame(width: 24)
            
            Text(weatherType)
                .font(.subheadline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)件")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MonthlyStatRow: View {
    let period: String
    let days: Int
    let offset: Int
    
    init(period: String, days: Int, offset: Int = 0) {
        self.period = period
        self.days = days
        self.offset = offset
    }
    
    var records: [WeatherRecord] {
        let endDate = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return WeatherHistoryService.shared.loadRecords(from: startDate, to: endDate)
    }
    
    var averageTemp: Double {
        let temperatures = records.map { $0.temperature }
        return temperatures.isEmpty ? 0 : temperatures.reduce(0, +) / Double(temperatures.count)
    }
    
    var body: some View {
        HStack {
            Text(period)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(records.count)件")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                if !records.isEmpty {
                    Text(String(format: "平均%.1f°C", averageTemp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DatabaseInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    static let relative: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}