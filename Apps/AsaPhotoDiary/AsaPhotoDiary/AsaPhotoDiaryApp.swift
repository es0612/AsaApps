//
//  AsaPhotoDiaryApp.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/06
//

import SwiftUI

@main
struct AsaPhotoDiaryApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
