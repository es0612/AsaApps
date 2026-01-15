import SwiftUI
#if FIREBASE_ENABLED
import FirebaseCore
import FirebaseMessaging
import UserNotifications
#endif

// MARK: - App Delegate

#if FIREBASE_ENABLED
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    // MARK: - App Launch

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase初期化
        FirebaseApp.configure()

        // プッシュ通知設定
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // 通知権限リクエスト
        requestNotificationAuthorization(application)

        return true
    }

    // MARK: - Notification Authorization

    private func requestNotificationAuthorization(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドで通知を表示
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 通知タップ時の処理
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped with userInfo: \(userInfo)")
        completionHandler()
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM Token: \(token)")

        // トークンをサーバーに保存（AuthViewModelで処理）
        NotificationCenter.default.post(
            name: Notification.Name("FCMTokenReceived"),
            object: nil,
            userInfo: ["token": token]
        )
    }
}
#endif

// MARK: - App

@main
struct AsaSocialFeedApp: App {
    #if FIREBASE_ENABLED
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #else
    @State private var viewModel: FeedViewModel
    #endif

    init() {
        #if !FIREBASE_ENABLED
        do {
            let dataService = try SocialFeedDataService()
            _viewModel = State(initialValue: FeedViewModel(dataService: dataService))
        } catch {
            fatalError("データサービス初期化エラー: \(error)")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if FIREBASE_ENABLED
            FirebaseContentView()
            #else
            ContentView(viewModel: viewModel)
            #endif
        }
    }
}
