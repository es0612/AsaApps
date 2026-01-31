import SwiftUI

// MARK: - PowerToggleView

/// 電源トグルボタン
struct PowerToggleView: View {
    // MARK: - Properties

    @Binding var isOn: Bool
    let onToggle: () async -> Void
    var isLoading: Bool = false
    var size: CGFloat = 50

    @State private var isAnimating = false

    // MARK: - Body

    var body: some View {
        Button {
            Task {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAnimating = true
                }
                await onToggle()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAnimating = false
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                    .shadow(color: shadowColor, radius: isOn ? 8 : 0)

                if isLoading || isAnimating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "power")
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        isOn ? Color.asaCoffeeBrown : Color.white.opacity(0.15)
    }

    private var iconColor: Color {
        isOn ? .white : .white.opacity(0.6)
    }

    private var shadowColor: Color {
        isOn ? Color.asaCoffeeBrown.opacity(0.5) : .clear
    }
}

// MARK: - Preview

#Preview("Power Toggle") {
    VStack(spacing: 40) {
        HStack(spacing: 40) {
            PowerToggleView(isOn: .constant(true), onToggle: {})
            PowerToggleView(isOn: .constant(false), onToggle: {})
        }

        HStack(spacing: 40) {
            PowerToggleView(isOn: .constant(true), onToggle: {}, isLoading: true)
            PowerToggleView(isOn: .constant(false), onToggle: {}, size: 70)
        }
    }
    .padding()
    .background(Color.asaDarkSlate)
}
