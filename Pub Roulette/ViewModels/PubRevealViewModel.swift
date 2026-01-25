import Foundation
import SwiftUI
import UIKit

@Observable
final class PubRevealViewModel {
    private let partyService = PartyService.shared

    var revealedIndices: Set<Int> = []
    var isShuffling: Bool = false
    var shuffleOffsets: [CGSize] = []
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
        shuffleOffsets = Array(repeating: .zero, count: 10)
    }

    func startShuffleAnimation() async {
        isShuffling = true

        for _ in 0..<8 {
            withAnimation(.easeInOut(duration: 0.15)) {
                shuffleOffsets = shuffleOffsets.indices.map { _ in
                    CGSize(
                        width: CGFloat.random(in: -30...30),
                        height: CGFloat.random(in: -20...20)
                    )
                }
            }
            try? await Task.sleep(for: .milliseconds(150))
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            shuffleOffsets = Array(repeating: .zero, count: shuffleOffsets.count)
        }

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
