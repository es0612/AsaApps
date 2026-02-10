import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct SettingsView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                securitySection
                personalSection
                financialSection
                aboutSection
            }
            .navigationTitle("設定")
            .onAppear {
                viewModel.loadSettings()
                viewModel.checkBiometrics()
            }
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section("セキュリティ") {
            if viewModel.canUseBiometrics {
                Toggle(isOn: $viewModel.isBiometricEnabled) {
                    Label(
                        biometricLabel,
                        systemImage: biometricIcon
                    )
                }
                .tint(AsaColors.coffeeBrown)
                .onChange(of: viewModel.isBiometricEnabled) { _, newValue in
                    if newValue {
                        Task { await viewModel.authenticate() }
                    }
                    viewModel.saveSettings()
                }
            } else {
                Label("生体認証は利用できません", systemImage: "lock.slash")
                    .foregroundStyle(AsaColors.mutedSage)
            }
        }
    }

    // MARK: - Personal

    private var personalSection: some View {
        Section("個人情報") {
            Stepper("現在の年齢: \(viewModel.currentAge)歳", value: $viewModel.currentAge, in: 18...100)
                .onChange(of: viewModel.currentAge) { _, _ in viewModel.saveSettings() }

            Stepper("退職予定年齢: \(viewModel.retirementAge)歳", value: $viewModel.retirementAge, in: 50...80)
                .onChange(of: viewModel.retirementAge) { _, _ in viewModel.saveSettings() }

            HStack {
                Text("退職までの年数")
                    .foregroundStyle(AsaColors.darkSlate)
                Spacer()
                Text("\(max(viewModel.retirementAge - viewModel.currentAge, 0))年")
                    .fontWeight(.medium)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }
        }
    }

    // MARK: - Financial

    private var financialSection: some View {
        Section("金融設定") {
            Picker("通貨", selection: $viewModel.currencyCode) {
                Text("JPY (円)").tag("JPY")
                Text("USD ($)").tag("USD")
            }
            .onChange(of: viewModel.currencyCode) { _, _ in viewModel.saveSettings() }

            PercentageSlider(
                title: "デフォルトインフレ率",
                value: Binding(
                    get: { NSDecimalNumber(decimal: viewModel.defaultInflationRate).doubleValue },
                    set: { viewModel.defaultInflationRate = Decimal($0); viewModel.saveSettings() }
                ),
                range: 0.0...0.10,
                step: 0.005
            )

            CurrencyTextField(
                title: "月間生活費",
                value: $viewModel.monthlyLivingExpense,
                currencyCode: viewModel.currencyCode
            )
            .onChange(of: viewModel.monthlyLivingExpense) { _, _ in viewModel.saveSettings() }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("情報") {
            HStack {
                Text("アプリ名")
                Spacer()
                Text("AsaFinancePlanner")
                    .foregroundStyle(AsaColors.mutedSage)
            }
            HStack {
                Text("バージョン")
                Spacer()
                Text("1.0")
                    .foregroundStyle(AsaColors.mutedSage)
            }
            HStack {
                Text("開発者")
                Spacer()
                Text("朝活パパエンジニア")
                    .foregroundStyle(AsaColors.mutedSage)
            }
        }
    }

    // MARK: - Helpers

    private var biometricLabel: String {
        switch viewModel.biometricType {
        case .faceID: return "Face IDで保護"
        case .touchID: return "Touch IDで保護"
        case .none: return "生体認証"
        }
    }

    private var biometricIcon: String {
        switch viewModel.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock"
        }
    }
}
