import SwiftUI
#if FIREBASE_ENABLED
import FirebaseCore
import FirebaseAuth
#endif

#if FIREBASE_ENABLED
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase初期化完了")
        return true
    }
}
#endif

@main
struct AsaFamilySyncApp: App {
    #if FIREBASE_ENABLED
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    // サービスの初期化
    private let authService: AuthService
    private let dataService: FamilyDataService

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var familyGroupViewModel: FamilyGroupViewModel

    init() {
        #if FIREBASE_ENABLED
        // Firebase初期化（サービス作成前に必須）
        FirebaseApp.configure()
        print("🔥 Firebase初期化完了")
        #endif

        // Firebaseサービスを使用
        print("🔥 Firebase モード: Firebaseサービスを使用します")
        let firebaseAuthService = FirebaseAuthService()
        let firebaseDataService = FirebaseDataService()

        self.authService = firebaseAuthService
        self.dataService = firebaseDataService

        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: firebaseAuthService))
        _familyGroupViewModel = StateObject(wrappedValue: FamilyGroupViewModel(dataService: firebaseDataService))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(familyGroupViewModel)
        }
    }
}
