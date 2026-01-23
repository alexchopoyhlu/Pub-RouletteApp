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

        let spinDuration = Constants.slotSpinDuration

        for i in 0..<drinks.count {
            let delay = Double(i) * 0.3
            let duration = spinDuration + delay

            Task {
                try? await Task.sleep(for: .seconds(delay))

                let spinCycles = 10 + i * 2
                let spinDistance = CGFloat(spinCycles * 60)

                withAnimation(.linear(duration: duration * 0.8)) {
                    slotOffsets[i] = spinDistance
                }

                try? await Task.sleep(for: .seconds(duration * 0.8))

                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
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
