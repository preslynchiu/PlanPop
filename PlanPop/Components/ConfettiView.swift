//
//  ConfettiView.swift
//  PlanPop
//
//  Fun confetti animation when all tasks are completed
//

import SwiftUI

/// A single confetti piece
struct ConfettiPiece: View {
    // Random properties for this piece
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let delay: Double

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: x, y: isAnimating ? 800 : -50)
            .rotationEffect(.degrees(isAnimating ? Double.random(in: 0...360) : 0))
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeIn(duration: Double.random(in: 2...3))
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// Full-screen confetti celebration
struct ConfettiView: View {
    // Pastel confetti colors
    let colors: [Color] = [
        Color(hex: "#FF9EAA"), // Pink
        Color(hex: "#FFD4A0"), // Peach
        Color(hex: "#FFF5A0"), // Yellow
        Color(hex: "#A0FFA0"), // Green
        Color(hex: "#A0FFFF"), // Cyan
        Color(hex: "#A0D4FF"), // Blue
        Color(hex: "#D4A0FF"), // Purple
    ]

    // Number of confetti pieces
    let numberOfPieces = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<numberOfPieces, id: \.self) { index in
                    ConfettiPiece(
                        color: colors[index % colors.count],
                        size: CGFloat.random(in: 8...16),
                        x: CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2),
                        delay: Double(index) * 0.02
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false) // Don't block touches
    }
}

// MARK: - View Modifier for Easy Use

struct ConfettiModifier: ViewModifier {
    @Binding var isShowing: Bool

    func body(content: Content) -> some View {
        ZStack {
            content

            if isShowing {
                ConfettiView()
                    .transition(.opacity)
            }
        }
    }
}

extension View {
    /// Add confetti celebration overlay
    func confetti(isShowing: Binding<Bool>) -> some View {
        modifier(ConfettiModifier(isShowing: isShowing))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.background
            .ignoresSafeArea()

        VStack {
            Text("🎉")
                .font(.system(size: 100))
            Text("Congratulations!")
                .font(.title)
                .fontWeight(.bold)
        }

        ConfettiView()
    }
}
