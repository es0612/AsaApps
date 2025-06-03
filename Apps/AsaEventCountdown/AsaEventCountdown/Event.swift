// AsaApps/Apps/AsaEventCountdown/Models/Event.swift
import Foundation

struct Event: Codable, Identifiable {
    let id = UUID()
    let name: String
    let date: Date
}
