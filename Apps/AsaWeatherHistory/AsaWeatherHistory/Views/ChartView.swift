import SwiftUI
import Charts

struct ChartView: View {
    @StateObject private var historyService = WeatherHistoryService.shared
    
    @State private var selectedPeriod: ChartPeriod = .week
    @State private var selectedDataType: DataType = .temperature
    
    enum ChartPeriod: String, CaseIterable {
        case week = "1週間"
        case month = "1ヶ月"
        case threeMonths = "3ヶ月"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    enum DataType: String, CaseIterable {
        case temperature = "気温"
        case humidity = "湿度"
        case pressure = "気圧"
        case windSpeed = "風速"
        
        var unit: String {
            switch self {
            case .temperature: return "°C"
            case .humidity: return "%"
            case .pressure: return "hPa"
            case .windSpeed: return "m/s"
            }
        }
        
        var color: Color {
            switch self {
            case .temperature: return Color("AsaCoffeeBrown")
            case .humidity: return .blue
            case .pressure: return .green
            case .windSpeed: return Color("AsaMutedSage")
            }
        }
        
        var icon: String {
            switch self {
            case .temperature: return "thermometer"
            case .humidity: return "drop.fill"
            case .pressure: return "barometer"
            case .windSpeed: return "wind"
            }
        }
    }
    
    var chartData: [ChartDataPoint] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) ?? endDate
        let records = historyService.loadRecords(from: startDate, to: endDate)
        
        return records.map { record in
            let value: Double
            switch selectedDataType {
            case .temperature:
                value = record.temperature
            case .humidity:
                value = Double(record.humidity)
            case .pressure:
                value = Double(record.pressure)
            case .windSpeed:
                value = record.windSpeed
            }
            
            return ChartDataPoint(
                date: record.recordDate,
                value: value,
                location: record.locationName ?? "不明"
            )
        }.sorted { $0.date < $1.date }
    }
    
    var statisticData: StatisticData {
        let values = chartData.map { $0.value }
        return StatisticData(
            average: values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count),
            min: values.min() ?? 0,
            max: values.max() ?? 0,
            count: values.count
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間・データタイプ選択
                    selectionControls
                    
                    if chartData.isEmpty {
                        emptyChartView
                    } else {
                        // 統計カード
                        statisticsCard
                        
                        // チャート
                        chartCard
                        
                        // データポイントリスト
                        dataPointsList
                    }
                }
                .padding()
            }
            .navigationTitle("データ分析")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            historyService.loadRecentRecords(limit: 200)
        }
    }
    
    // MARK: - Selection Controls
    private var selectionControls: some View {
        VStack(spacing: 12) {
            // 期間選択
            VStack(alignment: .leading, spacing: 8) {
                Text("期間")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // データタイプ選択
            VStack(alignment: .leading, spacing: 8) {
                Text("データタイプ")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Picker("データタイプ", selection: $selectedDataType) {
                    ForEach(DataType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("AsaSoftCream").opacity(0.3))
        )
    }
    
    // MARK: - Statistics Card
    private var statisticsCard: some View {
        AsaCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: selectedDataType.icon)
                        .foregroundColor(selectedDataType.color)
                    Text("\(selectedDataType.rawValue)統計")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatItem(
                        title: "平均",
                        value: String(format: "%.1f", statisticData.average),
                        unit: selectedDataType.unit,
                        color: selectedDataType.color
                    )
                    
                    StatItem(
                        title: "最小",
                        value: String(format: "%.1f", statisticData.min),
                        unit: selectedDataType.unit,
                        color: .blue
                    )
                    
                    StatItem(
                        title: "最大",
                        value: String(format: "%.1f", statisticData.max),
                        unit: selectedDataType.unit,
                        color: .red
                    )
                    
                    StatItem(
                        title: "データ数",
                        value: "\(statisticData.count)",
                        unit: "件",
                        color: Color("AsaMutedSage")
                    )
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Chart Card
    private var chartCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("\(selectedDataType.rawValue)推移")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Text("過去\(selectedPeriod.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Chart(chartData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("日時", dataPoint.date),
                        y: .value(selectedDataType.rawValue, dataPoint.value)
                    )
                    .foregroundStyle(selectedDataType.color)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("日時", dataPoint.date),
                        y: .value(selectedDataType.rawValue, dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [selectedDataType.color.opacity(0.3), selectedDataType.color.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    PointMark(
                        x: .value("日時", dataPoint.date),
                        y: .value(selectedDataType.rawValue, dataPoint.value)
                    )
                    .foregroundStyle(selectedDataType.color)
                    .symbolSize(20)
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(String(format: "%.0f", doubleValue))\(selectedDataType.unit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Data Points List
    private var dataPointsList: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("データポイント")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Text("\(chartData.count)件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(chartData.suffix(10), id: \.date) { dataPoint in
                        DataPointRow(
                            dataPoint: dataPoint,
                            dataType: selectedDataType
                        )
                    }
                }
                
                if chartData.count > 10 {
                    Text("最新10件を表示")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Empty Chart View
    private var emptyChartView: some View {
        AsaCard {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(Color("AsaMutedSage"))
                
                VStack(spacing: 8) {
                    Text("データがありません")
                        .font(.title2.weight(.medium))
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("選択した期間にデータが存在しません")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    Task {
                        await historyService.fetchAndSaveCurrentWeather()
                    }
                } label: {
                    Text("データを取得")
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
            .padding(40)
        }
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct DataPointRow: View {
    let dataPoint: ChartDataPoint
    let dataType: ChartView.DataType
    
    var body: some View {
        HStack {
            Image(systemName: dataType.icon)
                .foregroundColor(dataType.color)
                .frame(width: 20)
            
            Text(DateFormatter.monthDay.string(from: dataPoint.date))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(DateFormatter.hourMinute.string(from: dataPoint.date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(dataPoint.location)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text("\(String(format: "%.1f", dataPoint.value))\(dataType.unit)")
                .font(.subheadline.weight(.medium))
                .foregroundColor(dataType.color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models
struct ChartDataPoint {
    let date: Date
    let value: Double
    let location: String
}

struct StatisticData {
    let average: Double
    let min: Double
    let max: Double
    let count: Int
}

// MARK: - Date Formatters
extension DateFormatter {
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
    
    static let hourMinute: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}