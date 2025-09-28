import SwiftUI
import AsaUIKit

struct ARPlaneDetectionGuideView: View {
    let guideMessage: String?
    let isPlaneDetected: Bool

    @State private var animationPhase = 0.0

    var body: some View {
        VStack {
            if let message = guideMessage {
                AsaCard {
                    HStack(spacing: 12) {
                        if !isPlaneDetected {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.title2)
                                .foregroundColor(AsaColors.coffeeBrown)
                                .rotationEffect(.degrees(animationPhase))
                                .onAppear {
                                    withAnimation(
                                        .linear(duration: 2.0)
                                        .repeatForever(autoreverses: false)
                                    ) {
                                        animationPhase = 360
                                    }
                                }
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }

                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(AsaColors.darkSlate)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(12)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: guideMessage)
            }
        }
        .padding(.horizontal)
    }
}

struct PlaneDetectionIndicator: View {
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(AsaColors.coffeeBrown.opacity(0.3), lineWidth: 2)
                .frame(width: 120, height: 120)

            Circle()
                .stroke(AsaColors.coffeeBrown.opacity(0.6), lineWidth: 2)
                .frame(width: 90, height: 90)
                .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                .opacity(pulseAnimation ? 0.0 : 1.0)

            Circle()
                .stroke(AsaColors.coffeeBrown, lineWidth: 3)
                .frame(width: 60, height: 60)

            Image(systemName: "camera.fill")
                .font(.title)
                .foregroundColor(AsaColors.coffeeBrown)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                pulseAnimation = true
            }
        }
    }
}

#Preview("Guide Message") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            ARPlaneDetectionGuideView(
                guideMessage: "カメラを床や机などの平面に向けてください",
                isPlaneDetected: false
            )

            Spacer()
        }
        .padding(.top, 50)
    }
}

#Preview("Plane Detected") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            ARPlaneDetectionGuideView(
                guideMessage: "目のアイコンをタップして名刺を表示",
                isPlaneDetected: true
            )

            Spacer()
        }
        .padding(.top, 50)
    }
}

#Preview("Detection Indicator") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        PlaneDetectionIndicator()
    }
}