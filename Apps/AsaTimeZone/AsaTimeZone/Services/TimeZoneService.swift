import Foundation

final class TimeZoneService {
    private let userDefaults = UserDefaults.standard
    private let timeZoneItemsKey = "AsaTimeZone.timeZoneItems"
    private let globalClockStyleKey = "AsaTimeZone.globalClockStyle"

    func loadTimeZones() -> [TimeZoneItem] {
        guard let data = userDefaults.data(forKey: timeZoneItemsKey),
              let items = try? JSONDecoder().decode([TimeZoneItem].self, from: data) else {
            return []
        }
        return items
    }

    func saveTimeZones(_ items: [TimeZoneItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(data, forKey: timeZoneItemsKey)
    }

    func loadGlobalClockStyle() -> ClockStyle {
        guard let rawValue = userDefaults.string(forKey: globalClockStyleKey),
              let style = ClockStyle(rawValue: rawValue) else {
            return .analog
        }
        return style
    }

    func saveGlobalClockStyle(_ style: ClockStyle) {
        userDefaults.set(style.rawValue, forKey: globalClockStyleKey)
    }

    func clearAllData() {
        userDefaults.removeObject(forKey: timeZoneItemsKey)
        userDefaults.removeObject(forKey: globalClockStyleKey)
    }
}