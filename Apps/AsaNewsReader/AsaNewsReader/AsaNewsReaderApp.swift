//
//  AsaNewsReaderApp.swift
//  AsaNewsReader
//  
//  Created on 2025/07/07
//

import SwiftUI

@main
struct AsaNewsReaderApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
