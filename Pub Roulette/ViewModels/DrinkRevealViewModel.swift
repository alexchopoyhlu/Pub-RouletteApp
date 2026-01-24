import Foundation
import SwiftUI

@Observable
final class DrinkRevealViewModel {
    private let partyService = PartyService.shared

    var slotOffsets: [CGFloat] = []
    var isSpinning: Bool = false
    var revealedCount: Int = 0
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

    var drinks: [String] {
        myTeam?.drinkOrder ?? []
    }

    var pubs: [Pub] {
        guard let team = myTeam, let party = party else { return [] }
        return team.pubOrder.compactMap { index in
            party.pubs[safe: index]
        }
    }

    init() {
        slotOffsets = Array(repeating: 0, count: 10)
    }

    func startSlotAnimation() async {
        isSpinning = true

        let itemHeight: CGFloat = 60
        let drinkCount = CGFloat(Constants.drinkTypes.count)

        for i in 0..<drinks.count {
            // Staggered delay - first one starts immediately, subsequent ones wait for previous to settle
            let delay = Double(i) * 2.5  // 2.5 seconds between each reveal

            Task {
                try? await Task.sleep(for: .seconds(delay))

                // Fast initial spin
                let spinCycles = 8 + i * 2
                let spinDistance = CGFloat(spinCycles) * itemHeight * drinkCount

                // Phase 1: Fast spinning (0.8 seconds)
                withAnimation(.linear(duration: 0.8)) {
                    slotOffsets[i] = spinDistance * 0.6
                }

                try? await Task.sleep(for: .seconds(0.8))

                // Phase 2: Slowing down (0.6 seconds)
                withAnimation(.easeOut(duration: 0.6)) {
                    slotOffsets[i] = spinDistance * 0.9
                }

                try? await Task.sleep(for: .seconds(0.6))

                // Phase 3: Final slowdown with satisfying snap (0.4 seconds)
                // Calculate the snap position to align with the target drink
                let targetIndex = Constants.drinkTypes.firstIndex(of: drinks[i]) ?? 0
                let snapOffset = CGFloat(targetIndex) * itemHeight
                let finalOffset = spinDistance + snapOffset

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1)) {
                    slotOffsets[i] = finalOffset
                }

                try? await Task.sleep(for: .seconds(0.3))

                // Reveal the drink
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    slotOffsets[i] = 0
                }

                await MainActor.run {
                    revealedCount = max(revealedCount, i + 1)
                    if revealedCount >= drinks.count {
                        allRevealed = true
                        isSpinning = false
                    }
                }
            }
        }
    }

    func proceedToCrawl() async {
        do {
            try await partyService.finishDrinkReveal()
        } catch {
            print("Error proceeding to crawl: \(error)")
        }
    }
}
