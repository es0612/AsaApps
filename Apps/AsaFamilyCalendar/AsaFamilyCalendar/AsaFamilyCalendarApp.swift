//
//  AsaFamilyCalendarApp.swift
//  AsaFamilyCalendar
//  
//  Created on 2025/07/04
//


import SwiftUI

@main
struct AsaFamilyCalendarApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
