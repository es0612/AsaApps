import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - 図形パズルビュー

/// 図形パズルモード固有UI
/// 図形をSwiftUIのShape/Pathで描画し、選択肢をグリッド表示
struct ShapePuzzleView: View {

    // MARK: - Properties

    @Bindable var gameVM: GameViewModel
    @State private var shapeVM = ShapePuzzleViewModel()

    // MARK: - State

    @State private var selectedOption: String?
    @State private var showResult: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // 問題表示
            questionSection

            // 図形表示エリア
            shapeDisplaySection

            // 選択肢
            optionsSection

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: gameVM.currentQuestion) { _, newQuestion in
            if let question = newQuestion {
                shapeVM.setupForQuestion(question)
                resetState()
            }
        }
        .onAppear {
            if let question = gameVM.currentQuestion {
                shapeVM.setupForQuestion(question)
            }
        }
    }

    // MARK: - 問題表示セクション

    private var questionSection: some View {
        VStack(spacing: 8) {
            if let question = gameVM.currentQuestion {
                Text(question.questionText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - 図形描画セクション

    private var shapeDisplaySection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            // 図形の名前に応じて描画
            drawShape(name: shapeVM.currentShapeName)
                .frame(width: 120, height: 120)
        }
        .frame(height: 180)
    }

    /// 図形名に基づいてSwiftUI Shapeを描画
    @ViewBuilder
    private func drawShape(name: String) -> some View {
        switch name {
        case "まる":
            Circle()
                .fill(AsaColors.coffeeBrown.opacity(0.7))
                .overlay(Circle().stroke(AsaColors.coffeeBrown, lineWidth: 3))
        case "さんかく":
            Triangle()
                .fill(AsaColors.mutedSage.opacity(0.7))
                .overlay(Triangle().stroke(AsaColors.mutedSage, lineWidth: 3))
        case "しかく":
            Rectangle()
                .fill(Color.blue.opacity(0.5))
                .overlay(Rectangle().stroke(Color.blue, lineWidth: 3))
        case "ほし":
            StarShape(points: 5)
                .fill(Color.yellow.opacity(0.7))
                .overlay(StarShape(points: 5).stroke(Color.orange, lineWidth: 3))
        case "ハート":
            HeartShape()
                .fill(Color.red.opacity(0.6))
                .overlay(HeartShape().stroke(Color.red, lineWidth: 3))
        case "ひしがた":
            DiamondShape()
                .fill(Color.cyan.opacity(0.5))
                .overlay(DiamondShape().stroke(Color.cyan, lineWidth: 3))
        default:
            Circle()
                .fill(AsaColors.softCream)
                .overlay(
                    Text("?")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                )
        }
    }

    // MARK: - 選択肢セクション

    private var optionsSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(shapeVM.shapeOptions.enumerated()), id: \.offset) { _, option in
                optionButton(option: option)
            }
        }
    }

    /// 選択肢ボタン
    private func optionButton(option: String) -> some View {
        Button {
            selectOption(option)
        } label: {
            Text(option)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(optionTextColor(option))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(optionBackgroundColor(option))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
        }
        .disabled(showResult)
        .accessibilityLabel("こたえ \(option)")
    }

    /// 選択肢テキスト色
    private func optionTextColor(_ option: String) -> Color {
        guard showResult else { return AsaColors.darkSlate }
        if option == gameVM.currentQuestion?.correctAnswer { return .white }
        if option == selectedOption { return .white }
        return AsaColors.darkSlate.opacity(0.5)
    }

    /// 選択肢背景色
    private func optionBackgroundColor(_ option: String) -> Color {
        guard showResult else { return Color.white }
        if option == gameVM.currentQuestion?.correctAnswer { return .green }
        if option == selectedOption { return .red.opacity(0.8) }
        return Color.white.opacity(0.5)
    }

    // MARK: - アクション

    private func selectOption(_ option: String) {
        guard !showResult else { return }
        selectedOption = option
        showResult = true
        gameVM.submitAnswer(option)
    }

    private func resetState() {
        selectedOption = nil
        showResult = false
    }
}

// MARK: - カスタムシェイプ

/// 三角形
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// 星型
struct StarShape: Shape {
    let points: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let totalPoints = points * 2

        var path = Path()
        for i in 0..<totalPoints {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// ハート型
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.3),
            control1: CGPoint(x: width * 0.1, y: height * 0.7),
            control2: CGPoint(x: 0, y: height * 0.5)
        )
        path.addCurve(
            to: CGPoint(x: width / 2, y: height * 0.3),
            control1: CGPoint(x: 0, y: height * 0.05),
            control2: CGPoint(x: width * 0.35, y: height * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.3),
            control1: CGPoint(x: width * 0.65, y: height * 0.05),
            control2: CGPoint(x: width, y: height * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width, y: height * 0.5),
            control2: CGPoint(x: width * 0.9, y: height * 0.7)
        )

        return path
    }
}

/// ひし形
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ShapePuzzleView(
        gameVM: GameViewModel(
            dataService: EduGameDataService(inMemory: true),
            questionGenerator: QuestionGeneratorService(),
            scoringService: ScoringService(),
            difficultyService: AdaptiveDifficultyService()
        )
    )
}
