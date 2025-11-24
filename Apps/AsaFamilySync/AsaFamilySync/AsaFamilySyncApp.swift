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
        #if DEBUG
        // DEBUGモード: ローカルサービスを使用
        print("🔧 DEBUG モード: ローカルサービスを使用します")
        let localAuthService = LocalAuthService()
        let localDataService = LocalFamilyDataService()

        self.authService = localAuthService
        self.dataService = localDataService

        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: localAuthService))
        _familyGroupViewModel = StateObject(wrappedValue: FamilyGroupViewModel(dataService: localDataService))
        #else
        // RELEASEモード: Firebaseサービスを使用
        print("🔥 RELEASE モード: Firebaseサービスを使用します")
        // TODO: Firebase版のサービスを実装
        // let firebaseAuthService = FirebaseAuthService()
        // let firebaseDataService = FirebaseDataService()
        //
        // self.authService = firebaseAuthService
        // self.dataService = firebaseDataService
        //
        // _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: firebaseAuthService))
        // _familyGroupViewModel = StateObject(wrappedValue: FamilyGroupViewModel(dataService: firebaseDataService))

        // 暫定的にローカルサービスを使用
        let localAuthService = LocalAuthService()
        let localDataService = LocalFamilyDataService()

        self.authService = localAuthService
        self.dataService = localDataService

        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: localAuthService))
        _familyGroupViewModel = StateObject(wrappedValue: FamilyGroupViewModel(dataService: localDataService))
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(familyGroupViewModel)
        }
    }
}
