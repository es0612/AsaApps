import Foundation
import SwiftUI
import Combine

@MainActor
class TimeZoneViewModel: ObservableObject {
    @Published var timeZoneItems: [TimeZoneItem] = []
    @Published var currentTime = Date()
    @Published var globalClockStyle: ClockStyle = .analog

    private let service = TimeZoneService()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadTimeZones()
        startTimer()

        $timeZoneItems
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] items in
                self?.saveTimeZones(items)
            }
            .store(in: &cancellables)
    }

    deinit {
        stopTimer()
    }

    func loadTimeZones() {
        timeZoneItems = service.loadTimeZones()
        if timeZoneItems.isEmpty {
            timeZoneItems = TimeZoneItem.defaultTimeZones
        }
    }

    func saveTimeZones(_ items: [TimeZoneItem]) {
        service.saveTimeZones(items)
    }

    func addTimeZone(_ item: TimeZoneItem) {
        guard timeZoneItems.count < 6 else { return }
        guard !timeZoneItems.contains(where: { $0.identifier == item.identifier }) else { return }
        timeZoneItems.append(item)
    }

    func removeTimeZone(at offsets: IndexSet) {
        timeZoneItems.remove(atOffsets: offsets)
    }

    func moveTimeZone(from source: IndexSet, to destination: Int) {
        timeZoneItems.move(fromOffsets: source, toOffset: destination)
    }

    func toggleClockStyle(for item: TimeZoneItem) {
        if let index = timeZoneItems.firstIndex(where: { $0.id == item.id }) {
            timeZoneItems[index].clockStyle.toggle()
        }
    }

    func toggleGlobalClockStyle() {
        globalClockStyle.toggle()
        for index in timeZoneItems.indices {
            timeZoneItems[index].clockStyle = globalClockStyle
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func timeString(for item: TimeZoneItem) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = item.timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }

    func dateString(for item: TimeZoneItem) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = item.timeZone
        formatter.dateFormat = "yyyy年MM月dd日 (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: currentTime)
    }

    func timeDifference(from item1: TimeZoneItem, to item2: TimeZoneItem) -> String {
        let seconds1 = item1.timeZone.secondsFromGMT(for: currentTime)
        let seconds2 = item2.timeZone.secondsFromGMT(for: currentTime)
        let difference = (seconds2 - seconds1) / 3600

        if difference == 0 {
            return "時差なし"
        } else if difference > 0 {
            return "\(difference)時間進んでいます"
        } else {
            return "\(abs(difference))時間遅れています"
        }
    }
}