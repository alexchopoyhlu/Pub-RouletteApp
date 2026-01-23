import SwiftUI

struct WheelView: View {
    let teams: [Team]
    let rotation: Double

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2 - 10

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
                    let labelRadius = radius * 0.65

                    Text(team.name.split(separator: " ").first.map(String.init) ?? team.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        .position(
                            x: center.x + labelRadius * cos(midAngle * .pi / 180),
                            y: center.y + labelRadius * sin(midAngle * .pi / 180)
                        )
                        .rotationEffect(.degrees(midAngle + 90))
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
                .fill(Color.red)
                .frame(width: 30, height: 25)
                .shadow(radius: 2)

            Rectangle()
                .fill(Color.red)
                .frame(width: 8, height: 10)
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

#Preview {
    VStack {
        WheelPointer()

        WheelView(
            teams: [
                Team(name: "Red Roosters", colorHex: "#E53935"),
                Team(name: "Blue Brewers", colorHex: "#1E88E5"),
                Team(name: "Green Guzzlers", colorHex: "#43A047"),
                Team(name: "Orange Ales", colorHex: "#FB8C00")
            ],
            rotation: 0
        )
        .frame(width: 300, height: 300)
    }
}
