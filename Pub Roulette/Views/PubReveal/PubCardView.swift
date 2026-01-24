import SwiftUI

struct PubCardView: View {
    let pub: Pub
    let index: Int
    let isRevealed: Bool
    let isFinal: Bool

    @State private var isFlipped = false

    var body: some View {
        ZStack {
            cardBack
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            cardFront
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onChange(of: isRevealed) { _, revealed in
            withAnimation(.easeInOut(duration: Constants.cardFlipDuration)) {
                isFlipped = revealed
            }
        }
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 100)
            .overlay {
                VStack {
                    Image(systemName: "questionmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Pub #\(index + 1)")
                        .font(.bricolage(.caption))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
    }

    private var cardFront: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isFinal ? Color.orange : Color(.secondarySystemGroupedBackground))
            .frame(height: 100)
            .overlay {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("#\(index + 1)")
                            .font(.bricolage(.caption))
                            .foregroundStyle(isFinal ? .white.opacity(0.8) : .secondary)

                        if isFinal {
                            Text("FINAL")
                                .font(.bricolage(.caption2))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Capsule())
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }

                    Text(pub.name)
                        .font(.bricolage(.headline))
                        .foregroundStyle(isFinal ? .white : .primary)

                    Text(pub.address)
                        .font(.bricolage(.caption))
                        .foregroundStyle(isFinal ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }
                .padding()
            }
            .shadow(color: isFinal ? .orange.opacity(0.3) : .clear, radius: 10)
    }
}

#Preview {
    VStack(spacing: 16) {
        PubCardView(
            pub: Pub(name: "The Red Lion", address: "123 Main St", latitude: 0, longitude: 0),
            index: 0,
            isRevealed: false,
            isFinal: false
        )

        PubCardView(
            pub: Pub(name: "The Crown", address: "456 High St", latitude: 0, longitude: 0),
            index: 1,
            isRevealed: true,
            isFinal: false
        )

        PubCardView(
            pub: Pub(name: "The Final Stop", address: "789 End Rd", latitude: 0, longitude: 0),
            index: 2,
            isRevealed: true,
            isFinal: true
        )
    }
    .padding()
}
