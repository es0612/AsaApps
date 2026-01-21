import SwiftUI
import RealityKit
import ARKit
import AsaUIKit

// MARK: - ContentView
struct ContentView: View {
    @Environment(ARGameViewModel.self) private var viewModel

    // MARK: - Body

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            // AR View
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()

            // UI Overlay
            overlayContent
        }
        .sheet(isPresented: $viewModel.showingOnboarding) {
            OnboardingView {
                viewModel.completeOnboarding()
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $viewModel.showingGameOver) {
            GameOverView(
                statistics: viewModel.gameStatistics,
                onRestart: {
                    viewModel.showingGameOver = false
                    viewModel.restartGame()
                },
                onClose: {
                    viewModel.showingGameOver = false
                }
            )
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $viewModel.showingPauseMenu) {
            pauseMenuView
        }
        .onAppear {
            viewModel.setupAR()
        }
    }

    // MARK: - Overlay Content

    @ViewBuilder
    private var overlayContent: some View {
        switch viewModel.gameState {
        case .idle, .waitingForPlane:
            waitingOverlay

        case .ready:
            readyOverlay

        case .playing:
            playingOverlay

        case .paused:
            // 一時停止中はHUDのみ表示
            pausedOverlay

        case .gameOver:
            // ゲームオーバーはsheetで表示
            EmptyView()
        }
    }

    // MARK: - Waiting Overlay

    private var waitingOverlay: some View {
        VStack {
            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
                    .padding()
            }

            // ガイド
            ARPlaneGuideView(
                guideMessage: viewModel.guideMessage,
                isPlaneDetected: viewModel.isPlaneDetected,
                gameState: viewModel.gameState
            )
            .padding(.top, 100)

            Spacer()
        }
    }

    // MARK: - Ready Overlay

    private var readyOverlay: some View {
        VStack {
            // ガイド
            ARPlaneGuideView(
                guideMessage: viewModel.guideMessage,
                isPlaneDetected: viewModel.isPlaneDetected,
                gameState: viewModel.gameState
            )
            .padding(.top, 100)

            Spacer()

            // スタートボタン
            startButton
                .padding(.bottom, 60)
        }
    }

    // MARK: - Playing Overlay

    private var playingOverlay: some View {
        VStack {
            // HUD
            GameHUDView(
                score: viewModel.score.currentScore,
                remainingTime: viewModel.remainingTime,
                comboCount: viewModel.score.comboCount,
                highScore: viewModel.highScore,
                onPause: {
                    viewModel.pauseGame()
                }
            )

            Spacer()
        }
    }

    // MARK: - Paused Overlay

    private var pausedOverlay: some View {
        VStack {
            // HUD（一時停止状態）
            GameHUDView(
                score: viewModel.score.currentScore,
                remainingTime: viewModel.remainingTime,
                comboCount: viewModel.score.comboCount,
                highScore: viewModel.highScore,
                onPause: {}
            )

            Spacer()

            // 一時停止中の表示
            VStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("一時停止中")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))

            Spacer()
        }
    }

    // MARK: - Pause Menu View

    private var pauseMenuView: some View {
        NavigationView {
            ZStack {
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // タイトル
                    VStack(spacing: 8) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AsaColors.coffeeBrown)

                        Text("一時停止")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AsaColors.darkSlate)
                    }

                    // 現在のスコア
                    AsaCard {
                        VStack(spacing: 8) {
                            Text("現在のスコア")
                                .font(.subheadline)
                                .foregroundColor(AsaColors.mutedSage)
                            Text("\(viewModel.score.currentScore)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(AsaColors.coffeeBrown)
                            Text("残り時間: \(Int(viewModel.remainingTime))秒")
                                .font(.subheadline)
                                .foregroundColor(AsaColors.mutedSage)
                        }
                    }

                    Spacer()

                    // ボタン
                    VStack(spacing: 16) {
                        // 再開ボタン
                        Button {
                            viewModel.showingPauseMenu = false
                            viewModel.resumeGame()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("再開")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AsaColors.coffeeBrown, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // 終了ボタン
                        Button {
                            viewModel.showingPauseMenu = false
                            viewModel.endGame()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("ゲームを終了")
                            }
                            .font(.headline)
                            .foregroundColor(AsaColors.coffeeBrown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AsaColors.coffeeBrown, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Subviews

    private var startButton: some View {
        Button {
            viewModel.startGame()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("START")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [AsaColors.coffeeBrown, AsaColors.mocha],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .shadow(color: AsaColors.coffeeBrown.opacity(0.5), radius: 10, y: 5)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3), value: viewModel.gameState)
    }

    private func errorView(message: String) -> some View {
        AsaCard {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()

                Button("閉じる") {
                    viewModel.clearError()
                }
                .font(.caption)
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(ARGameViewModel())
}
