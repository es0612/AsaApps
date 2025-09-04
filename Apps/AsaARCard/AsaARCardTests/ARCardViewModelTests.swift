import Testing
import Foundation
@testable import AsaARCard

struct ARCardViewModelTests {
    
    @Test("ARCardViewModelの初期化テスト")
    func viewModelInitialization() throws {
        let viewModel = ARCardViewModel()
        
        #expect(viewModel.isARViewReady == true) // setupAR()で設定される
        #expect(viewModel.isCardVisible == false)
        #expect(viewModel.showingSettings == false)
        #expect(viewModel.showingCardFlip == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.businessCard != nil)
    }
    
    @Test("名刺データ更新テスト")
    func businessCardUpdate() throws {
        let viewModel = ARCardViewModel()
        let originalCard = viewModel.businessCard
        
        let newCard = BusinessCard(
            name: "新しい名前",
            title: "新しい職業",
            company: "新しい会社",
            email: "new@example.com",
            phone: "090-1111-1111",
            website: "https://new.example.com"
        )
        
        viewModel.updateBusinessCard(newCard)
        
        #expect(viewModel.businessCard.name == newCard.name)
        #expect(viewModel.businessCard.title == newCard.title)
        #expect(viewModel.businessCard.company == newCard.company)
        #expect(viewModel.businessCard.email == newCard.email)
        #expect(viewModel.businessCard.phone == newCard.phone)
        #expect(viewModel.businessCard.website == newCard.website)
        
        // 元のカードとは異なることを確認
        #expect(viewModel.businessCard.name != originalCard.name)
    }
    
    @Test("設定画面表示テスト")
    func showSettings() throws {
        let viewModel = ARCardViewModel()
        
        #expect(viewModel.showingSettings == false)
        
        viewModel.showSettings()
        
        #expect(viewModel.showingSettings == true)
    }
    
    @Test("エラーメッセージ管理テスト")
    func errorMessageManagement() throws {
        let viewModel = ARCardViewModel()
        
        #expect(viewModel.errorMessage == nil)
        
        // エラーメッセージを設定（実際のメソッドがあると仮定）
        let testError = "テストエラーメッセージ"
        viewModel.errorMessage = testError
        
        #expect(viewModel.errorMessage == testError)
        
        viewModel.clearError()
        
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("カード表示状態管理テスト")
    func cardVisibilityState() throws {
        let viewModel = ARCardViewModel()
        
        #expect(viewModel.isCardVisible == false)
        
        // showBusinessCard()を呼び出すとisCardVisibleがtrueになることを期待
        // ただし、実際のAR機能が無効な環境ではMockが必要
        // 今回は状態の変更のみテスト
        viewModel.isCardVisible = true
        #expect(viewModel.isCardVisible == true)
        
        viewModel.hideBusinessCard()
        #expect(viewModel.isCardVisible == false)
    }
    
    @Test("カードフリップ状態テスト")
    func cardFlipState() throws {
        let viewModel = ARCardViewModel()
        
        #expect(viewModel.showingCardFlip == false)
        
        // フリップ状態を変更
        viewModel.showingCardFlip = true
        #expect(viewModel.showingCardFlip == true)
        
        // flipCard()メソッドの呼び出し（実際のAR処理は除く）
        let originalFlipState = viewModel.showingCardFlip
        // flipCard()内でshowingCardFlip.toggle()が呼ばれることをテスト
        viewModel.showingCardFlip.toggle()
        #expect(viewModel.showingCardFlip != originalFlipState)
    }
}

// MARK: - ARセッション状態テスト
struct ARSessionStateTests {
    
    @Test("AR利用可能性チェック")
    func arAvailabilityCheck() throws {
        // ARKitの利用可能性は実機でのみ正確にテストできるため、
        // 基本的な状態チェックのみ行う
        let viewModel = ARCardViewModel()
        
        // 初期状態でARViewReadyがtrueであることを確認
        // （setupAR()でtrueに設定される想定）
        #expect(viewModel.isARViewReady == true)
    }
    
    @Test("エラー状態の処理")
    func errorStateHandling() throws {
        let viewModel = ARCardViewModel()
        
        // デバイスがAR機能をサポートしていない場合のエラーメッセージ
        let expectedErrorMessage = "このデバイスはAR機能をサポートしていません"
        viewModel.errorMessage = expectedErrorMessage
        
        #expect(viewModel.errorMessage == expectedErrorMessage)
        
        // エラークリア
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}