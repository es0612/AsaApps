import SwiftUI
import SwiftData
#if FIREBASE_ENABLED
import FirebaseCore
#endif

@main
struct AsaExpenseSyncApp: App {
    // MARK: - Properties

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var expenseViewModel: ExpenseViewModel

    // MARK: - Initialization

    init() {
        #if FIREBASE_ENABLED
        FirebaseApp.configure()
        print("AsaExpenseSync: Firebase initialized")

        let authService: AuthServiceProtocol = FirebaseExpenseAuthService()
        let dataService: ExpenseDataServiceProtocol = FirestoreExpenseDataService()
        #else
        let authService: AuthServiceProtocol = MockAuthService()
        let dataService: ExpenseDataServiceProtocol = MockExpenseDataService()
        print("AsaExpenseSync: Running with mock services")
        #endif

        _authViewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
        _expenseViewModel = StateObject(wrappedValue: ExpenseViewModel(dataService: dataService))
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(expenseViewModel)
        }
        .modelContainer(for: [LocalTransaction.self, LocalCategory.self])
    }
}
