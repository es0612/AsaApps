import SwiftUI
import CoreData

struct WeatherDetailView: View {
    let record: WeatherRecord
    
    @State private var showingMap = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ヘッダーカード
                headerCard
                
                // 基本情報カード
                basicInfoCard
                
                // 詳細情報カード
                detailInfoCard
                
                // 風情報カード
                windInfoCard
                
                // 位置情報カード
                locationInfoCard
            }
            .padding()
        }
        .navigationTitle("天気詳細")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("AsaSoftCream").opacity(0.3),
                    Color("AsaDarkSlate").opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        AsaCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(record.locationName ?? "不明な場所")
                            .font(.title.weight(.bold))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text(record.displayDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: record.weatherIconName)
                        .font(.system(size: 60))
                        .foregroundColor(Color(record.weatherColor))
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(record.temperatureString)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text(record.weatherDescription ?? "")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        temperatureRangeView
                        feelsLikeView
                    }
                }
            }
            .padding(20)
        }
    }
    
    private var temperatureRangeView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "thermometer.sun")
                    .foregroundColor(.red)
                Text("最高")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f°C", record.maxTemperature))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "thermometer.snowflake")
                    .foregroundColor(.blue)
                Text("最低")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f°C", record.minTemperature))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var feelsLikeView: some View {
        HStack(spacing: 8) {
            Image(systemName: "person")
                .foregroundColor(Color("AsaCoffeeBrown"))
            Text("体感温度")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f°C", record.feelsLikeTemperature))
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
    
    // MARK: - Basic Info Card
    private var basicInfoCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("基本情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    InfoItem(
                        icon: "drop.fill",
                        title: "湿度",
                        value: "\(record.humidity)%",
                        color: .blue
                    )
                    
                    InfoItem(
                        icon: "barometer",
                        title: "気圧",
                        value: "\(record.pressure) hPa",
                        color: .green
                    )
                    
                    InfoItem(
                        icon: "eye.fill",
                        title: "天気コード",
                        value: "\(record.weatherCode)",
                        color: Color("AsaMutedSage")
                    )
                    
                    InfoItem(
                        icon: "calendar",
                        title: "記録日時",
                        value: DateFormatter.shortTime.string(from: record.recordDate),
                        color: Color("AsaCoffeeBrown")
                    )
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Detail Info Card
    private var detailInfoCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("詳細データ")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                VStack(spacing: 12) {
                    DetailRow(
                        title: "記録日時",
                        value: DateFormatter.full.string(from: record.recordDate),
                        icon: "clock.fill"
                    )
                    
                    DetailRow(
                        title: "作成日時",
                        value: DateFormatter.full.string(from: record.createdAt),
                        icon: "plus.circle.fill"
                    )
                    
                    if record.updatedAt != record.createdAt {
                        DetailRow(
                            title: "更新日時",
                            value: DateFormatter.full.string(from: record.updatedAt),
                            icon: "pencil.circle.fill"
                        )
                    }
                    
                    DetailRow(
                        title: "気温範囲",
                        value: String(format: "%.1f°C ~ %.1f°C", record.minTemperature, record.maxTemperature),
                        icon: "thermometer"
                    )
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Wind Info Card
    private var windInfoCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "wind")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("風情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                HStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "speedometer")
                            .font(.title)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("風速")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f m/s", record.windSpeed))
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        windDirectionIcon
                        
                        Text("風向")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(windDirectionText)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        windStrengthIcon
                        
                        Text("強さ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(windStrengthText)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(windStrengthColor)
                    }
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Location Info Card
    private var locationInfoCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("位置情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Button {
                        showingMap = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "map.fill")
                            Text("地図")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color("AsaCoffeeBrown"))
                        )
                    }
                }
                
                VStack(spacing: 12) {
                    DetailRow(
                        title: "都市名",
                        value: record.locationName ?? "不明",
                        icon: "building.2.fill"
                    )
                    
                    DetailRow(
                        title: "国",
                        value: record.country ?? "不明",
                        icon: "flag.fill"
                    )
                    
                    DetailRow(
                        title: "緯度",
                        value: String(format: "%.4f°", record.latitude),
                        icon: "globe"
                    )
                    
                    DetailRow(
                        title: "経度",
                        value: String(format: "%.4f°", record.longitude),
                        icon: "globe"
                    )
                    
                    if let sunrise = record.sunrise {
                        DetailRow(
                            title: "日の出",
                            value: DateFormatter.timeOnly.string(from: sunrise),
                            icon: "sunrise.fill"
                        )
                    }
                    
                    if let sunset = record.sunset {
                        DetailRow(
                            title: "日の入り",
                            value: DateFormatter.timeOnly.string(from: sunset),
                            icon: "sunset.fill"
                        )
                    }
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showingMap) {
            // 地図表示ビュー（簡易実装）
            NavigationView {
                VStack {
                    Text("地図表示")
                        .font(.title)
                        .padding()
                    
                    Text("緯度: \(String(format: "%.4f", record.latitude))")
                    Text("経度: \(String(format: "%.4f", record.longitude))")
                    
                    Spacer()
                }
                .navigationTitle("位置")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("閉じる") {
                            showingMap = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Wind Helpers
    private var windDirectionIcon: some View {
        Image(systemName: "location.north.line.fill")
            .font(.title)
            .foregroundColor(Color("AsaMutedSage"))
            .rotationEffect(.degrees(Double(record.windDirection)))
    }
    
    private var windDirectionText: String {
        let directions = ["北", "北東", "東", "南東", "南", "南西", "西", "北西"]
        let index = Int((Double(record.windDirection) + 22.5) / 45.0) % 8
        return directions[index]
    }
    
    private var windStrengthIcon: some View {
        Group {
            if record.windSpeed < 1.0 {
                Image(systemName: "leaf.fill")
            } else if record.windSpeed < 5.0 {
                Image(systemName: "wind")
            } else if record.windSpeed < 10.0 {
                Image(systemName: "tornado")
            } else {
                Image(systemName: "hurricane")
            }
        }
        .font(.title)
        .foregroundColor(windStrengthColor)
    }
    
    private var windStrengthText: String {
        switch record.windSpeed {
        case 0..<1.0:
            return "静穏"
        case 1.0..<5.0:
            return "微風"
        case 5.0..<10.0:
            return "軽風"
        case 10.0..<15.0:
            return "軟風"
        default:
            return "強風"
        }
    }
    
    private var windStrengthColor: Color {
        switch record.windSpeed {
        case 0..<1.0:
            return .green
        case 1.0..<5.0:
            return Color("AsaMutedSage")
        case 5.0..<10.0:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Supporting Views
struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            
            Spacer()
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("AsaMutedSage"))
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: 80, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}