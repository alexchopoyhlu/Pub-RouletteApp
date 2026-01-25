import SwiftUI

enum MeshGradientTheme {
    case sunset // orange, pink, yellow, purple
    case midnight // blue, purple, black
    case aurora // green, teal, cyan for team assignment
    case amber // warm amber, gold, brown for pub reveal
    case monochrome // black, gray, white for settings

    var colors: [[Color]] {
        switch self {
        case .sunset:
            return [
                [.purple, .indigo, .indigo, .purple],
                [.indigo, .orange, .pink, .indigo],
                [.pink, .yellow, .orange, .pink],
                [.yellow, .orange, .pink, .yellow]
            ]
        case .midnight:
            return [
                [.black, Color(red: 0.1, green: 0.0, blue: 0.2), Color(red: 0.1, green: 0.0, blue: 0.2), .black],
                [Color(red: 0.1, green: 0.0, blue: 0.3), .indigo, .purple, Color(red: 0.1, green: 0.0, blue: 0.3)],
                [Color(red: 0.0, green: 0.1, blue: 0.4), .blue, .indigo, Color(red: 0.0, green: 0.1, blue: 0.4)],
                [.black, Color(red: 0.0, green: 0.1, blue: 0.3), Color(red: 0.0, green: 0.1, blue: 0.3), .black]
            ]
        case .aurora:
            return [
                [Color(red: 0.0, green: 0.1, blue: 0.1), Color(red: 0.0, green: 0.2, blue: 0.2), Color(red: 0.0, green: 0.2, blue: 0.2), Color(red: 0.0, green: 0.1, blue: 0.1)],
                [Color(red: 0.0, green: 0.3, blue: 0.3), .teal, .cyan, Color(red: 0.0, green: 0.3, blue: 0.3)],
                [Color(red: 0.0, green: 0.4, blue: 0.3), .green, .teal, Color(red: 0.0, green: 0.4, blue: 0.3)],
                [Color(red: 0.0, green: 0.15, blue: 0.15), Color(red: 0.0, green: 0.25, blue: 0.2), Color(red: 0.0, green: 0.25, blue: 0.2), Color(red: 0.0, green: 0.15, blue: 0.15)]
            ]
        case .amber:
            return [
                [Color(red: 0.15, green: 0.08, blue: 0.0), Color(red: 0.2, green: 0.1, blue: 0.0), Color(red: 0.2, green: 0.1, blue: 0.0), Color(red: 0.15, green: 0.08, blue: 0.0)],
                [Color(red: 0.3, green: 0.15, blue: 0.0), Color(red: 0.8, green: 0.5, blue: 0.1), Color(red: 0.9, green: 0.6, blue: 0.2), Color(red: 0.3, green: 0.15, blue: 0.0)],
                [Color(red: 0.4, green: 0.2, blue: 0.05), Color(red: 0.7, green: 0.4, blue: 0.1), Color(red: 0.6, green: 0.35, blue: 0.1), Color(red: 0.4, green: 0.2, blue: 0.05)],
                [Color(red: 0.1, green: 0.05, blue: 0.0), Color(red: 0.2, green: 0.1, blue: 0.02), Color(red: 0.2, green: 0.1, blue: 0.02), Color(red: 0.1, green: 0.05, blue: 0.0)]
            ]
        case .monochrome:
            return [
                [.black, Color(white: 0.1), Color(white: 0.1), .black],
                [Color(white: 0.15), Color(white: 0.3), Color(white: 0.35), Color(white: 0.15)],
                [Color(white: 0.2), Color(white: 0.4), Color(white: 0.35), Color(white: 0.2)],
                [.black, Color(white: 0.15), Color(white: 0.15), .black]
            ]
        }
    }

    var flatColors: [Color] {
        colors.flatMap { $0 }
    }
}

@available(iOS 18.0, *)
struct AnimatedMeshGradient: View {
    let theme: MeshGradientTheme

    init(theme: MeshGradientTheme = .sunset) {
        self.theme = theme
    }

    var body: some View {
        TimelineView(.animation) { context in
            let speed: Double = 0.6
            let time = context.date.timeIntervalSince1970 * speed

            let offset1 = Float(sin(time)) * 0.2
            let offset2 = Float(cos(time * 0.8)) * 0.2
            let offset3 = Float(sin(time * 1.2)) * 0.15
            let offset4 = Float(cos(time * 0.9)) * 0.15

            MeshGradient(
                width: 4,
                height: 4,
                points: [
                    [0.0, 0.0], [0.33, 0.0], [0.66, 0.0], [1.0, 0.0],
                    [0.0, 0.33],
                    [0.33 + offset1, 0.33 + offset2],
                    [0.66 - offset2, 0.33 + offset1],
                    [1.0, 0.33],
                    [0.0, 0.66],
                    [0.33 - offset3, 0.66 - offset4],
                    [0.66 + offset4, 0.66 - offset3],
                    [1.0, 0.66],
                    [0.0, 1.0], [0.33, 1.0], [0.66, 1.0], [1.0, 1.0]
                ],
                colors: theme.flatColors
            )
        }
        .ignoresSafeArea()
    }
}

struct AnimatedMeshGradientFallback: View {
    @State private var animate = false
    let theme: MeshGradientTheme

    init(theme: MeshGradientTheme = .sunset) {
        self.theme = theme
    }

    private var backgroundColor: Color {
        switch theme {
        case .sunset: return .indigo
        case .midnight: return .black
        case .aurora: return Color(red: 0.0, green: 0.15, blue: 0.15)
        case .amber: return Color(red: 0.15, green: 0.08, blue: 0.0)
        case .monochrome: return .black
        }
    }

    private var circleColors: [Color] {
        switch theme {
        case .sunset: return [.purple, .pink, .orange, .yellow]
        case .midnight: return [.indigo, .purple, .blue, Color(red: 0.2, green: 0.0, blue: 0.4)]
        case .aurora: return [.teal, .cyan, .green, Color(red: 0.0, green: 0.5, blue: 0.4)]
        case .amber: return [Color(red: 0.8, green: 0.5, blue: 0.1), Color(red: 0.9, green: 0.6, blue: 0.2), Color(red: 0.7, green: 0.4, blue: 0.1), Color(red: 0.6, green: 0.35, blue: 0.1)]
        case .monochrome: return [Color(white: 0.3), Color(white: 0.4), Color(white: 0.35), Color(white: 0.25)]
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor

                Circle()
                    .fill(circleColors[0])
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: animate ? -50 : 100, y: animate ? -100 : 50)

                Circle()
                    .fill(circleColors[1])
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: animate ? 100 : -80, y: animate ? 150 : -50)

                Circle()
                    .fill(circleColors[2])
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: animate ? -80 : 60, y: animate ? 50 : 150)

                Circle()
                    .fill(circleColors[3])
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(x: animate ? 80 : -40, y: animate ? -150 : 100)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct MeshGradientBackground: View {
    let theme: MeshGradientTheme

    init(theme: MeshGradientTheme = .sunset) {
        self.theme = theme
    }

    var body: some View {
        if #available(iOS 18.0, *) {
            AnimatedMeshGradient(theme: theme)
        } else {
            AnimatedMeshGradientFallback(theme: theme)
        }
    }
}

#Preview("Sunset") {
    MeshGradientBackground(theme: .sunset)
}

#Preview("Midnight") {
    MeshGradientBackground(theme: .midnight)
}

#Preview("Aurora") {
    MeshGradientBackground(theme: .aurora)
}

#Preview("Amber") {
    MeshGradientBackground(theme: .amber)
}

#Preview("Monochrome") {
    MeshGradientBackground(theme: .monochrome)
}
