import Foundation

// MARK: - SettingsViewModel

/// 設定画面のViewModel
///
/// ユーザー設定の読み書きと生体認証管理を担当する。
@MainActor @Observable
public final class SettingsViewModel {
    // MARK: - Dependencies

    private let dataService: FinanceDataServiceProtocol
    private let authService: BiometricAuthService

    // MARK: - Properties

    public var settings: UserSettings?
    public var canUseBiometrics: Bool = false
    public var biometricType: BiometricType = .none
    public var isAuthenticated: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Settings Editing

    public var currencyCode: String = "JPY"
    public var currentAge: Int = 30
    public var retirementAge: Int = 65
    public var defaultInflationRate: Decimal = Decimal(sign: .plus, exponent: -2, significand: 2)
    public var isBiometricEnabled: Bool = false
    public var monthlyLivingExpense: Decimal = Decimal(250000)

    // MARK: - Initialization

    public init(
        dataService: FinanceDataServiceProtocol,
        authService: BiometricAuthService = BiometricAuthService()
    ) {
        self.dataService = dataService
        self.authService = authService
    }

    // MARK: - Methods

    /// 設定を読み込み、フォーム状態に反映
    public func loadSettings() {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try dataService.fetchSettings()
            settings = loaded
            currencyCode = loaded.currencyCode
            currentAge = loaded.currentAge
            retirementAge = loaded.retirementAge
            defaultInflationRate = loaded.defaultInflationRate
            isBiometricEnabled = loaded.isBiometricEnabled
            monthlyLivingExpense = loaded.monthlyLivingExpense
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        checkBiometrics()
    }

    /// フォーム状態の設定をデータサービスに保存
    public func saveSettings() {
        guard let settings else { return }
        settings.currencyCode = currencyCode
        settings.currentAge = currentAge
        settings.retirementAge = retirementAge
        settings.defaultInflationRate = defaultInflationRate
        settings.isBiometricEnabled = isBiometricEnabled
        settings.monthlyLivingExpense = monthlyLivingExpense
        do {
            try dataService.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 生体認証を実行
    public func authenticate() async {
        do {
            isAuthenticated = try await authService.authenticate()
        } catch {
            isAuthenticated = false
            errorMessage = error.localizedDescription
        }
    }

    /// 生体認証の利用可否をチェック
    public func checkBiometrics() {
        canUseBiometrics = authService.canUseBiometrics()
        biometricType = authService.biometricType()
    }
}
