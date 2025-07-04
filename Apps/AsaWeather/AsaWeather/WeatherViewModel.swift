import Foundation
import CoreLocation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var forecast: ForecastData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var isSearching = false
    
    private let weatherService = WeatherService.shared
    private var locationManager: LocationManager?
    
    init() {
        Task {
            await loadWeatherData()
        }
    }
    
    func loadWeatherData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let locationManager = locationManager, let location = locationManager.location {
                await loadWeatherForLocation(location)
            } else {
                await loadWeatherForDefaultCity()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func searchWeather(for cityName: String) async {
        guard !cityName.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let weather = try await weatherService.fetchWeather(for: cityName)
            currentWeather = weather
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshWeather() async {
        await loadWeatherData()
    }
    
    private func loadWeatherForLocation(_ location: CLLocation) async {
        do {
            async let weatherData = weatherService.fetchWeather(for: location)
            async let forecastData = weatherService.fetchForecast(for: location)
            
            currentWeather = try await weatherData
            forecast = try await forecastData
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadWeatherForDefaultCity() async {
        do {
            let weather = try await weatherService.fetchWeather(for: "東京")
            currentWeather = weather
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension WeatherViewModel {
    var dailyForecast: [DailyForecast] {
        guard let forecast = forecast else { return [] }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let groupedByDate = Dictionary(grouping: forecast.list) { item in
            dateFormatter.string(from: item.date)
        }
        
        return groupedByDate.compactMap { (dateString, items) in
            guard let firstItem = items.first else { return nil }
            
            let maxTemp = items.map { $0.main.tempMax }.max() ?? 0
            let minTemp = items.map { $0.main.tempMin }.min() ?? 0
            
            return DailyForecast(
                date: firstItem.date,
                maxTemp: maxTemp,
                minTemp: minTemp,
                weatherIconName: firstItem.weatherIconName,
                description: firstItem.weather.first?.description ?? ""
            )
        }
        .sorted { $0.date < $1.date }
        .prefix(5)
        .map { $0 }
    }
    
    var hasWeatherData: Bool {
        currentWeather != nil
    }
    
    var isLocationEnabled: Bool {
        locationManager?.isLocationEnabled ?? false
    }
    
    var locationErrorMessage: String? {
        locationManager?.errorMessage
    }
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let maxTemp: Double
    let minTemp: Double
    let weatherIconName: String
    let description: String
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    var temperatureString: String {
        return String(format: "%.0f°/%.0f°", maxTemp, minTemp)
    }
}