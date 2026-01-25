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

    private let itemHeight: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            let visibleItems = Int(geometry.size.height / itemHeight) + 2

            ZStack {
                if isRevealed {
                    DrinkIconView(drinkType: targetDrink, size: 50)
                } else {
                    VStack(spacing: 0) {
                        ForEach(0..<visibleItems * 3, id: \.self) { index in
                            let drinkIndex = index % Constants.drinkTypes.count
                            DrinkIconView(drinkType: Constants.drinkTypes[drinkIndex], size: 50)
                                .frame(height: itemHeight)
                        }
                    }
                    .offset(y: -offset.truncatingRemainder(dividingBy: itemHeight * CGFloat(Constants.drinkTypes.count)))
                    .blur(radius: offset > 0 ? 2 : 0)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
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
            isRevealed: true
        )
        .frame(height: 80)
        .background(Color.gray.opacity(0.1))
    }
    .padding()
}
