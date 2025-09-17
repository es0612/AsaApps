import Foundation

struct TimeZoneItem: Identifiable, Codable, Equatable {
    let id: UUID
    let identifier: String
    let cityName: String
    let countryName: String
    var clockStyle: ClockStyle

    init(identifier: String, cityName: String, countryName: String, clockStyle: ClockStyle = .analog) {
        self.id = UUID()
        self.identifier = identifier
        self.cityName = cityName
        self.countryName = countryName
        self.clockStyle = clockStyle
    }

    var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? TimeZone.current
    }

    var currentTime: Date {
        Date()
    }

    var offset: String {
        let seconds = TimeInterval(timeZone.secondsFromGMT(for: Date()))
        let hours = Int(seconds) / 3600
        let minutes = Int(abs(seconds).truncatingRemainder(dividingBy: 3600)) / 60
        let sign = hours >= 0 ? "+" : ""

        if minutes == 0 {
            return "GMT\(sign)\(hours)"
        } else {
            return "GMT\(sign)\(hours):\(String(format: "%02d", minutes))"
        }
    }

    func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }

    static var defaultTimeZones: [TimeZoneItem] {
        [
            TimeZoneItem(identifier: "Asia/Tokyo", cityName: "東京", countryName: "日本"),
            TimeZoneItem(identifier: "America/New_York", cityName: "ニューヨーク", countryName: "アメリカ"),
            TimeZoneItem(identifier: "Europe/London", cityName: "ロンドン", countryName: "イギリス"),
        ]
    }
}