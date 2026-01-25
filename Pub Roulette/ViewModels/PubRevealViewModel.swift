import Foundation
import SwiftUI

@Observable
final class PubRevealViewModel {
    private let partyService = PartyService.shared

    var revealedIndices: Set<Int> = []
    var isShuffling: Bool = false
    var cardOffsets: [CGFloat] = []  // Vertical offsets for shuffle
    var cardZIndices: [Double] = []  // Z-index for layering during shuffle
    var allRevealed: Bool = false

    var party: Party? {
        partyService.currentParty
    }

    var isHost: Bool {
        partyService.isHost
    }

    var myTeam: Team? {
        partyService.myTeam
    }

    var pubs: [Pub] {
        party?.pubs ?? []
    }

    var orderedPubs: [Pub] {
        guard let team = myTeam else { return pubs }
        return team.pubOrder.compactMap { index in
            pubs[safe: index]
        }
    }

    init() {
        cardOffsets = Array(repeating: 0, count: 10)
        cardZIndices = Array(repeating: 0, count: 10)
    }

    func startShuffleAnimation() async {
        // Wait for data to be available (up to 5 seconds)
        var attempts = 0
        while orderedPubs.isEmpty && attempts < 50 {
            try? await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        isShuffling = true
        let cardCount = orderedPubs.count
        guard cardCount > 1 else {
            isShuffling = false
            await revealCardsSequentially()
            return
        }

        let cardHeight: CGFloat = 112  // Approximate card height + spacing

        // Perform 3 shuffle passes
        for shufflePass in 0..<3 {
            // Gather cards to center (stack them)
            withAnimation(.easeInOut(duration: 0.3)) {
                for i in 0..<cardCount {
                    // Move all cards toward the center position
                    let centerIndex = CGFloat(cardCount - 1) / 2
                    let distanceFromCenter = CGFloat(i) - centerIndex
                    cardOffsets[i] = -distanceFromCenter * cardHeight * 0.8
                    // Higher cards (later in list) go on top during gather
                    cardZIndices[i] = Double(shufflePass % 2 == 0 ? i : cardCount - i)
                }
            }

            try? await Task.sleep(for: .milliseconds(300))

            // Scatter cards to new random-ish positions (simulating shuffle)
            withAnimation(.easeInOut(duration: 0.35)) {
                var positions = Array(0..<cardCount).shuffled()
                for i in 0..<cardCount {
                    let newPosition = positions[i]
                    let offset = CGFloat(newPosition - i) * cardHeight
                    cardOffsets[i] = offset
                    // Alternate which cards are on top
                    cardZIndices[i] = Double(newPosition)
                }
            }

            try? await Task.sleep(for: .milliseconds(350))
        }

        // Final gather - bring all cards back to original positions
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            for i in 0..<cardCount {
                cardOffsets[i] = 0
                cardZIndices[i] = 0
            }
        }

        try? await Task.sleep(for: .milliseconds(400))

        isShuffling = false

        await revealCardsSequentially()
    }

    func revealCardsSequentially() async {
        for i in 0..<orderedPubs.count {
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                revealedIndices.insert(i)
            }
            Haptics.medium()
        }
        Haptics.success()
        allRevealed = true
    }

    func proceedToDrinkReveal() async {
        do {
            try await partyService.finishPubReveal()
        } catch {
            print("Error proceeding to drink reveal: \(error)")
        }
    }
}
