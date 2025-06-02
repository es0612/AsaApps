// AsaApps/Apps/AsaMoodTracker/Models/MoodEntry.swift
import Foundation

struct MoodEntry: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let emoji: String
}
