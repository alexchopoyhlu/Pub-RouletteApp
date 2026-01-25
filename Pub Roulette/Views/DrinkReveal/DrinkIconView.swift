import SwiftUI

struct DrinkIconView: View {
    let drinkType: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(drinkColor.opacity(0.15))
                .frame(width: size, height: size)

            Text(drinkEmoji)
                .font(.system(size: size * 0.5))
        }
    }

    private var drinkEmoji: String {
        Constants.drinkEmojis[drinkType] ?? "🍺"
    }

    private var drinkColor: Color {
        if let hex = Constants.drinkColors[drinkType],
           let color = Color(hex: hex) {
            return color
        }
        return .gray
    }
}

struct DrinkSlotView: View {
    let drinks: [String]
    let targetDrink: String
    let offset: CGFloat
    let isRevealed: Bool
    let isSpinning: Bool

    private let itemHeight: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isRevealed {
                    DrinkIconView(drinkType: targetDrink, size: 50)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Create a seamless looping column of drinks
                    let totalHeight = itemHeight * CGFloat(drinks.count)
                    let normalizedOffset = offset.truncatingRemainder(dividingBy: totalHeight)

                    VStack(spacing: 0) {
                        // Repeat drinks 5 times for seamless looping
                        ForEach(0..<5, id: \.self) { repetition in
                            ForEach(Array(drinks.enumerated()), id: \.offset) { index, drink in
                                DrinkIconView(drinkType: drink, size: 50)
                                    .frame(height: itemHeight)
                            }
                        }
                    }
                    .offset(y: -normalizedOffset - totalHeight * 2 + geometry.size.height / 2 - itemHeight / 2)
                    .blur(radius: blurAmount)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    private var blurAmount: CGFloat {
        // Blur based on apparent speed (change in offset would indicate speed)
        // For now, blur when spinning
        isSpinning ? 1.5 : 0
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            DrinkIconView(drinkType: "Shot", size: 60)
            DrinkIconView(drinkType: "Wine", size: 60)
            DrinkIconView(drinkType: "Beer", size: 60)
            DrinkIconView(drinkType: "Cocktail", size: 60)
        }

        HStack(spacing: 20) {
            DrinkIconView(drinkType: "Spirits", size: 60)
            DrinkIconView(drinkType: "Cider", size: 60)
            DrinkIconView(drinkType: "Sparkling", size: 60)
            DrinkIconView(drinkType: "No-Alcohol", size: 60)
        }

        DrinkSlotView(
            drinks: Constants.drinkTypes,
            targetDrink: "Beer",
            offset: 0,
            isRevealed: false,
            isSpinning: false
        )
        .frame(height: 80)
        .background(Color.gray.opacity(0.1))
    }
    .padding()
}
