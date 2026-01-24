import SwiftUI
import UIKit

struct PlayerWheelView: View {
    let players: [Player]
    let segmentColors: [Color]
    let rotation: Double
    let onBorderCrossed: () -> Void

    @State private var lastSegmentIndex: Int = 0

    private static let wheelColors: [Color] = [
        Color(hex: "#E53935") ?? .red,
        Color(hex: "#1E88E5") ?? .blue,
        Color(hex: "#43A047") ?? .green,
        Color(hex: "#FDD835") ?? .yellow,
        Color(hex: "#8E24AA") ?? .purple,
        Color(hex: "#FB8C00") ?? .orange,
        Color(hex: "#00897B") ?? .teal,
        Color(hex: "#D81B60") ?? .pink
    ]

    static func generateColors(count: Int) -> [Color] {
        var colors: [Color] = []
        var availableColors = wheelColors.shuffled()
        for i in 0..<count {
            if availableColors.isEmpty {
                availableColors = wheelColors.shuffled()
            }
            colors.append(availableColors.removeFirst())
        }
        return colors
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                if players.isEmpty {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: size - 20, height: size - 20)

                    Text("All assigned!")
                        .font(.bricolage(.headline))
                        .foregroundStyle(.secondary)
                } else {
                    // Wheel segments
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        WheelSegment(
                            startAngle: segmentStartAngle(for: index),
                            endAngle: segmentEndAngle(for: index),
                            color: segmentColors[safe: index] ?? .gray
                        )
                    }

                    // Player names at angle
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, _ in
                        let midAngle = segmentMidAngle(for: index)
                        let radius = (size / 2 - 10) * 0.65

                        Text(players[index].name)
                            .font(.bricolage(size: players.count > 6 ? 12 : 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            .rotationEffect(.degrees(45))
                            .position(
                                x: size / 2 + radius * cos(CGFloat(midAngle) * .pi / 180),
                                y: size / 2 + radius * sin(CGFloat(midAngle) * .pi / 180)
                            )
                    }

                    // Center circle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .position(x: size / 2, y: size / 2)

                    // Outer ring
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: size - 20, height: size - 20)
                        .position(x: size / 2, y: size / 2)
                }
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: rotation) { oldValue, newValue in
            checkBorderCrossing(oldRotation: oldValue, newRotation: newValue)
        }
    }

    private func segmentStartAngle(for index: Int) -> Double {
        guard players.count > 0 else { return 0 }
        let segmentSize = 360.0 / Double(players.count)
        return segmentSize * Double(index) - 90
    }

    private func segmentEndAngle(for index: Int) -> Double {
        guard players.count > 0 else { return 0 }
        let segmentSize = 360.0 / Double(players.count)
        return segmentSize * Double(index + 1) - 90
    }

    private func segmentMidAngle(for index: Int) -> Double {
        (segmentStartAngle(for: index) + segmentEndAngle(for: index)) / 2
    }

    private func checkBorderCrossing(oldRotation: Double, newRotation: Double) {
        guard players.count > 0 else { return }
        let segmentSize = 360.0 / Double(players.count)

        let normalizedOld = oldRotation.truncatingRemainder(dividingBy: 360)
        let normalizedNew = newRotation.truncatingRemainder(dividingBy: 360)

        let oldSegment = Int(normalizedOld / segmentSize)
        let newSegment = Int(normalizedNew / segmentSize)

        if oldSegment != newSegment {
            onBorderCrossed()
        }
    }
}

struct WheelSegment: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2 - 10

            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(endAngle),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

struct WheelPointer: View {
    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(Color.black)
                .frame(width: 30, height: 25)
                .shadow(radius: 2)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// Keep old WheelView for backwards compatibility if needed
struct WheelView: View {
    let teams: [Team]
    let rotation: Double

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                ForEach(Array(teams.enumerated()), id: \.element.id) { index, team in
                    WheelSegment(
                        startAngle: segmentStartAngle(for: index),
                        endAngle: segmentEndAngle(for: index),
                        color: team.color
                    )
                }

                ForEach(Array(teams.enumerated()), id: \.element.id) { index, team in
                    let midAngle = segmentMidAngle(for: index)

                    Text(team.name.split(separator: " ").first.map(String.init) ?? team.name)
                        .font(.bricolage(size: 14))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        .rotationEffect(.degrees(midAngle))
                        .offset(y: -(size / 2 - 10) * 0.6)
                        .rotationEffect(.degrees(-midAngle))
                }

                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 2)

                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: size - 20, height: size - 20)
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func segmentStartAngle(for index: Int) -> Double {
        let segmentSize = 360.0 / Double(teams.count)
        return segmentSize * Double(index) - 90
    }

    private func segmentEndAngle(for index: Int) -> Double {
        let segmentSize = 360.0 / Double(teams.count)
        return segmentSize * Double(index + 1) - 90
    }

    private func segmentMidAngle(for index: Int) -> Double {
        (segmentStartAngle(for: index) + segmentEndAngle(for: index)) / 2
    }
}

#Preview {
    VStack {
        WheelPointer()

        PlayerWheelView(
            players: [
                Player(name: "Mark"),
                Player(name: "Alex"),
                Player(name: "Freddie"),
                Player(name: "Jonty")
            ],
            segmentColors: PlayerWheelView.generateColors(count: 4),
            rotation: 0,
            onBorderCrossed: {}
        )
        .frame(width: 300, height: 300)
    }
}
