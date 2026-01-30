import SwiftUI
#if FIREBASE_ENABLED
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
#endif

// MARK: - App Entry Point

@main
struct AsaEventLiveApp: App {
    // MARK: - Properties

    @State private var authViewModel: AuthViewModel

    // MARK: - Initialization

    init() {
        var useFirebase = false

        #if FIREBASE_ENABLED
        // GoogleService-Info.plistが存在する場合のみFirebaseを初期化
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()

            // Firestoreオフラインキャッシュ設定（100MB）
            let settings = Firestore.firestore().settings
            settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)
            Firestore.firestore().settings = settings

            useFirebase = true
        }
        #endif

        // サービス初期化（Firebase有効かつplist存在時はFirestore、それ以外はMock）
        let dataService: any EventDataServiceProtocol
        #if FIREBASE_ENABLED
        if useFirebase {
            dataService = FirestoreEventDataService()
        } else {
            dataService = MockEventDataService()
        }
        #else
        dataService = MockEventDataService()
        #endif

        _authViewModel = State(initialValue: AuthViewModel(dataService: dataService))
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
        }
    }
}
