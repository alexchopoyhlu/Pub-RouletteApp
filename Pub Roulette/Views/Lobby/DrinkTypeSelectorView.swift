import SwiftUI

struct DrinkTypeSelectorView: View {
    @Binding var selectedDrinkTypes: Set<String>
    let onToggle: (String) -> Void

    // Arrange drinks in stretcher bond pattern (offset rows)
    private let row1 = ["Shot", "Wine", "Beer"]
    private let row2 = ["Cocktail", "Spirits"]
    private let row3 = ["Cider", "Sparkling", "No-Alcohol"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Drink Types")
                .font(.bricolage(.headline))

            VStack(spacing: 8) {
                // Row 1 - 3 items
                HStack(spacing: 8) {
                    ForEach(row1, id: \.self) { drink in
                        drinkChip(for: drink)
                    }
                }

                // Row 2 - 2 items, offset for stretcher bond
                HStack(spacing: 8) {
                    Spacer()
                        .frame(width: 20)
                    ForEach(row2, id: \.self) { drink in
                        drinkChip(for: drink)
                    }
                    Spacer()
                        .frame(width: 20)
                }

                // Row 3 - 3 items
                HStack(spacing: 8) {
                    ForEach(row3, id: \.self) { drink in
                        drinkChip(for: drink)
                    }
                }
            }

            Text("\(selectedDrinkTypes.count) drink type\(selectedDrinkTypes.count == 1 ? "" : "s") selected")
                .font(.bricolage(.caption))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func drinkChip(for drink: String) -> some View {
        let isSelected = selectedDrinkTypes.contains(drink)
        let emoji = Constants.drinkEmojis[drink] ?? ""
        let colorHex = Constants.drinkColors[drink] ?? "#808080"
        let color = Color(hex: colorHex) ?? .gray

        Button {
            Haptics.selection()
            onToggle(drink)
        } label: {
            HStack(spacing: 4) {
                Text(drink)
                    .font(.bricolage(.caption))
                Text(emoji)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(isSelected ? 1.0 : 0.3))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color, lineWidth: isSelected ? 2 : 0)
            )
            .foregroundStyle(.white)
            .opacity(isSelected ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    DrinkTypeSelectorView(
        selectedDrinkTypes: .constant(Set(["Shot", "Wine", "Beer", "Cocktail"]))
    ) { _ in }
    .padding()
    .background(Color(.systemGroupedBackground))
}
