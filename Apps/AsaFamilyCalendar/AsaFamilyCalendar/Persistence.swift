//
//  Persistence.swift
//  AsaFamilyCalendar
//  
//  Created on 2025/07/04
//


import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // サンプル家族メンバーを作成
        let papa = FamilyMember(context: viewContext)
        papa.id = UUID()
        papa.name = "パパ"
        papa.color = "AsaCoffeeBrown"
        papa.isActive = true
        
        let mama = FamilyMember(context: viewContext)
        mama.id = UUID()
        mama.name = "ママ"
        mama.color = "AsaSoftCream"
        mama.isActive = true
        
        let child = FamilyMember(context: viewContext)
        child.id = UUID()
        child.name = "こども"
        child.color = "AsaMutedSage"
        child.isActive = true
        
        // サンプルイベントを作成
        let event1 = Event(context: viewContext)
        event1.id = UUID()
        event1.title = "家族でお出かけ"
        event1.eventDescription = "近所の公園に行く"
        event1.startDate = Date()
        event1.endDate = Calendar.current.date(byAdding: .hour, value: 3, to: Date())
        event1.isAllDay = false
        event1.category = "レジャー"
        event1.reminder = 30
        event1.createdDate = Date()
        event1.memberID = papa.id
        
        let event2 = Event(context: viewContext)
        event2.id = UUID()
        event2.title = "買い物"
        event2.eventDescription = "食材の買い出し"
        event2.startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        event2.isAllDay = true
        event2.category = "家事"
        event2.createdDate = Date()
        event2.memberID = mama.id
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AsaFamilyCalendar")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
