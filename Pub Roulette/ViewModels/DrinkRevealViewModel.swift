import Foundation
import SwiftUI

@Observable
final class DrinkRevealViewModel {
    private let partyService = PartyService.shared

    var slotOffsets: [CGFloat] = []
    var slotPhases: [SlotPhase] = []  // Track phase of each slot
    var isSpinning: Bool = false
    var revealedCount: Int = 0
    var allRevealed: Bool = false

    private let itemHeight: CGFloat = 60

    enum SlotPhase {
        case idle
        case spinning
        case stopping
        case revealed
    }

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
        slotPhases = Array(repeating: .idle, count: 10)
    }

    func startSlotAnimation() async {
        // Wait for data to be available (up to 5 seconds)
        var attempts = 0
        while drinks.isEmpty && attempts < 50 {
            try? await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        guard drinks.count > 0 else { return }

        isSpinning = true
        let drinkCount = drinks.count
        let totalHeight = itemHeight * CGFloat(Constants.drinkTypes.count)

        // Phase 1: Start all slots spinning simultaneously
        for i in 0..<drinkCount {
            slotPhases[i] = .spinning
            // Each slot spins a different amount (more for later slots)
            let spinDistance = totalHeight * CGFloat(4 + i)

            withAnimation(.linear(duration: 0.5)) {
                slotOffsets[i] = spinDistance * 0.3
            }
        }

        // Continue spinning while we wait
        try? await Task.sleep(for: .milliseconds(400))

        // Extend the spin for all slots
        for i in 0..<drinkCount {
            let spinDistance = totalHeight * CGFloat(4 + i)
            withAnimation(.linear(duration: 0.8)) {
                slotOffsets[i] = spinDistance * 0.7
            }
        }

        try? await Task.sleep(for: .milliseconds(600))

        // Phase 2: Cascade the stopping - one slot at a time
        for i in 0..<drinkCount {
            await stopSlot(at: i)
            // Small delay before next slot starts stopping
            try? await Task.sleep(for: .milliseconds(150))
        }
    }

    private func stopSlot(at index: Int) async {
        guard index < drinks.count else { return }

        slotPhases[index] = .stopping

        let targetDrink = drinks[index]
        let targetDrinkIndex = Constants.drinkTypes.firstIndex(of: targetDrink) ?? 0
        let totalHeight = itemHeight * CGFloat(Constants.drinkTypes.count)

        // Calculate final position that lands on target drink
        // Add extra rotations for visual effect, then land on target
        let extraRotations = totalHeight * CGFloat(2 + index)
        let targetOffset = CGFloat(targetDrinkIndex) * itemHeight
        let finalOffset = extraRotations + targetOffset

        // Slow down and stop with easing
        withAnimation(.easeOut(duration: 0.8 + Double(index) * 0.1)) {
            slotOffsets[index] = finalOffset
        }

        // Wait for animation to mostly complete
        try? await Task.sleep(for: .milliseconds(700 + index * 80))

        // Snap with spring for satisfying stop
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            // Normalize to exact position
            slotOffsets[index] = targetOffset
        }

        Haptics.medium()

        try? await Task.sleep(for: .milliseconds(200))

        // Reveal
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            slotPhases[index] = .revealed
            revealedCount = max(revealedCount, index + 1)
        }

        if revealedCount >= drinks.count {
            Haptics.success()
            allRevealed = true
            isSpinning = false
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
