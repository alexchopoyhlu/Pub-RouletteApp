import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let horizontalDrift: CGFloat
    let color: Color
    let rotation: Double
    let rotationSpeed: Double
    let scale: CGFloat
    let shape: ConfettiShape
    let delay: Double
    let fallDuration: Double

    enum ConfettiShape: CaseIterable {
        case circle
        case rectangle
        case triangle
    }
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var isAnimating = false

    let colors: [Color] = [
        Color(red: 1.0, green: 0.84, blue: 0.0),    // Gold
        Color(red: 1.0, green: 0.65, blue: 0.0),    // Orange
        Color(red: 0.93, green: 0.51, blue: 0.93),  // Violet
        Color(red: 0.0, green: 0.75, blue: 1.0),    // Sky blue
        Color(red: 0.0, green: 0.87, blue: 0.67),   // Mint
        Color(red: 1.0, green: 0.41, blue: 0.71),   // Hot pink
        .white,
        Color(red: 1.0, green: 0.94, blue: 0.63)    // Light gold
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiPieceView(
                        piece: piece,
                        isAnimating: isAnimating,
                        screenHeight: geometry.size.height
                    )
                }
            }
            .onAppear {
                generatePieces(in: geometry.size)
                // Small delay to ensure pieces are rendered before animating
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isAnimating = true
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func generatePieces(in size: CGSize) {
        pieces = (0..<100).map { index in
            ConfettiPiece(
                startX: CGFloat.random(in: 0...size.width),
                horizontalDrift: CGFloat.random(in: -80...80),
                color: colors.randomElement() ?? .yellow,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 360...1080),
                scale: CGFloat.random(in: 0.4...1.0),
                shape: ConfettiPiece.ConfettiShape.allCases.randomElement() ?? .rectangle,
                delay: Double(index) * 0.02,
                fallDuration: Double.random(in: 3.0...5.0)
            )
        }
    }
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let isAnimating: Bool
    let screenHeight: CGFloat

    var body: some View {
        confettiShape
            .frame(width: shapeWidth, height: shapeHeight)
            .scaleEffect(piece.scale)
            .rotationEffect(.degrees(isAnimating ? piece.rotation + piece.rotationSpeed : piece.rotation))
            .offset(
                x: piece.startX + (isAnimating ? piece.horizontalDrift : 0),
                y: isAnimating ? screenHeight + 100 : -50
            )
            .opacity(isAnimating ? 0.0 : 1.0)
            .animation(
                .easeOut(duration: piece.fallDuration)
                .delay(piece.delay),
                value: isAnimating
            )
    }

    @ViewBuilder
    private var confettiShape: some View {
        switch piece.shape {
        case .circle:
            Circle()
                .fill(piece.color)
        case .rectangle:
            Rectangle()
                .fill(piece.color)
        case .triangle:
            Triangle()
                .fill(piece.color)
        }
    }

    private var shapeWidth: CGFloat {
        switch piece.shape {
        case .circle: return 10
        case .rectangle: return 8
        case .triangle: return 12
        }
    }

    private var shapeHeight: CGFloat {
        switch piece.shape {
        case .circle: return 10
        case .rectangle: return 14
        case .triangle: return 12
        }
    }
}



#Preview {
    ZStack {
        MeshGradientBackground(theme: .victory)
        ConfettiView()
    }
}
