import Foundation
import SwiftUI
import UIKit

@Observable
final class DrinkRevealViewModel {
    private let partyService = PartyService.shared

    var slotOffsets: [CGFloat] = []
    var slotSpeeds: [CGFloat] = []  // Current speed of each slot
    var slotSpinning: [Bool] = []   // Whether each slot is currently spinning
    var isSpinning: Bool = false
    var revealedCount: Int = 0
    var allRevealed: Bool = false

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var slotStates: [SlotState] = []

    private let itemHeight: CGFloat = 60

    enum SlotState {
        case spinning(speed: CGFloat)
        case slowingDown(startSpeed: CGFloat, startTime: CFTimeInterval, duration: CGFloat)
        case stopped
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
        slotSpeeds = Array(repeating: 0, count: 10)
        slotSpinning = Array(repeating: false, count: 10)
        slotStates = Array(repeating: .stopped, count: 10)
    }

    deinit {
        stopDisplayLink()
    }

    func startSlotAnimation() async {
        guard drinks.count > 0 else { return }

        isSpinning = true
        let drinkCount = drinks.count

        // Initialize all slots to spin at slightly different speeds
        for i in 0..<drinkCount {
            let baseSpeed: CGFloat = 800 + CGFloat(i) * 50  // pixels per second
            slotStates[i] = .spinning(speed: baseSpeed)
            slotSpinning[i] = true
            slotOffsets[i] = CGFloat.random(in: 0...100)  // Random starting positions
        }

        // Start the display link for smooth animation
        await MainActor.run {
            startDisplayLink()
        }

        // Initial spin phase - all slots spin together
        try? await Task.sleep(for: .seconds(1.5))

        // Begin cascading slowdown
        for i in 0..<drinkCount {
            let slowdownDuration: CGFloat = 1.2 + CGFloat(i) * 0.1  // Later slots take slightly longer

            if case .spinning(let speed) = slotStates[i] {
                slotStates[i] = .slowingDown(
                    startSpeed: speed,
                    startTime: CACurrentMediaTime(),
                    duration: slowdownDuration
                )
            }

            // Wait for this slot to stop before starting next slot's slowdown
            try? await Task.sleep(for: .seconds(Double(slowdownDuration) + 0.3))
        }
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
        lastTimestamp = CACurrentMediaTime()
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateAnimation(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastTimestamp
        lastTimestamp = currentTime

        let totalHeight = itemHeight * CGFloat(Constants.drinkTypes.count)
        var allStopped = true

        for i in 0..<drinks.count {
            switch slotStates[i] {
            case .spinning(let speed):
                // Continuous spinning
                slotOffsets[i] += speed * CGFloat(deltaTime)
                slotOffsets[i] = slotOffsets[i].truncatingRemainder(dividingBy: totalHeight * 5)
                allStopped = false

            case .slowingDown(let startSpeed, let startTime, let duration):
                let elapsed = CGFloat(currentTime - startTime)
                let progress = min(elapsed / duration, 1.0)

                // Easing function for natural slowdown (ease out cubic)
                let easedProgress = 1 - pow(1 - progress, 3)

                // Calculate current speed (decreasing)
                let currentSpeed = startSpeed * (1 - easedProgress)

                // Update position
                slotOffsets[i] += currentSpeed * CGFloat(deltaTime)

                // Dynamic blur based on speed
                slotSpinning[i] = currentSpeed > 100

                if progress >= 1.0 {
                    // Snap to target drink position
                    snapToTarget(slotIndex: i)
                    slotStates[i] = .stopped
                    slotSpinning[i] = false
                    Haptics.medium()

                    // Short delay then reveal
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(200))
                        self.revealSlot(at: i)
                    }
                } else {
                    allStopped = false
                }

            case .stopped:
                // Waiting to be revealed
                break

            case .revealed:
                // Already revealed
                break
            }
        }

        if allStopped && revealedCount >= drinks.count {
            stopDisplayLink()
        }
    }

    private func snapToTarget(slotIndex: Int) {
        guard slotIndex < drinks.count else { return }

        let targetDrink = drinks[slotIndex]
        let targetIndex = Constants.drinkTypes.firstIndex(of: targetDrink) ?? 0
        let totalHeight = itemHeight * CGFloat(Constants.drinkTypes.count)

        // Calculate current position in the cycle
        let currentPos = slotOffsets[slotIndex].truncatingRemainder(dividingBy: totalHeight)

        // Calculate target position
        let targetPos = CGFloat(targetIndex) * itemHeight

        // Find the nearest snap point
        var adjustment = targetPos - currentPos
        if adjustment < -totalHeight / 2 {
            adjustment += totalHeight
        } else if adjustment > totalHeight / 2 {
            adjustment -= totalHeight
        }

        // Animate to snap position
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            slotOffsets[slotIndex] += adjustment
        }
    }

    private func revealSlot(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            slotStates[index] = .revealed
            revealedCount = max(revealedCount, index + 1)
        }

        if revealedCount >= drinks.count {
            Haptics.success()
            allRevealed = true
            isSpinning = false
            stopDisplayLink()
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
