import Foundation
import SwiftUI

@Observable
final class DrinkRevealViewModel {
    private let partyService = PartyService.shared

    /// Per-slot timing & landing plan, computed once when the animation starts.
    struct SlotPlan {
        let spinSpeed: CGFloat     // points per second while rolling
        let stopStart: Double      // seconds after animationStart when easing begins
        let stopDuration: Double   // seconds to ease from rolling speed onto the target
        let offsetAtStop: CGFloat  // continuous offset at the moment easing begins
        let finalOffset: CGFloat   // resting offset (lands the target drink centered)
    }

    let itemHeight: CGFloat = 60

    private(set) var slotPlans: [SlotPlan] = []
    private(set) var animationStart: Date?
    /// Discrete reveal flags, flipped with animation so the icon pop transitions.
    var revealedFlags: [Bool] = []
    var allRevealed: Bool = false

    // MARK: - Waterfall timing config
    private let baseSpin: Double = 1.6        // everyone rolls together for this long
    private let waterfallGap: Double = 0.9    // delay between each slot starting to stop
    private let stopDuration: Double = 1.0    // ease-onto-target duration
    private let loopsPerSecond: CGFloat = 0.8 // rolling speed in full reel loops

    // Preview/testing overrides — when set, used instead of the live party data.
    private var previewDrinks: [String]?
    private var previewPubs: [Pub]?

    var party: Party? { partyService.currentParty }
    var isHost: Bool { partyService.isHost }
    var myTeam: Team? { partyService.myTeam }

    var drinks: [String] { previewDrinks ?? myTeam?.drinkOrder ?? [] }

    var pubs: [Pub] {
        if let previewPubs { return previewPubs }
        guard let team = myTeam, let party = party else { return [] }
        return team.pubOrder.compactMap { party.pubs[safe: $0] }
    }

    /// Injects fixed pubs/drinks so the reveal can be exercised in SwiftUI previews.
    func configureForPreview(pubs: [Pub], drinks: [String]) {
        previewPubs = pubs
        previewDrinks = drinks
    }

    func startSlotAnimation() async {
        // Wait for data to be available (up to 5 seconds)
        var attempts = 0
        while drinks.isEmpty && attempts < 50 {
            try? await Task.sleep(for: .milliseconds(100))
            attempts += 1
        }

        guard !drinks.isEmpty else { return }

        // Reset so the animation can be re-run (e.g. from the preview button).
        allRevealed = false

        let drinkCount = drinks.count
        let reelCount = Constants.drinkTypes.count
        let totalHeight = itemHeight * CGFloat(reelCount)
        let spinSpeed = totalHeight * loopsPerSecond

        var plans: [SlotPlan] = []
        for i in 0..<drinkCount {
            let targetIndex = Constants.drinkTypes.firstIndex(of: drinks[i]) ?? 0
            let targetOffset = CGFloat(targetIndex) * itemHeight

            let stopStart = baseSpin + Double(i) * waterfallGap
            let offsetAtStop = spinSpeed * CGFloat(stopStart)

            // Land on the target a couple of full loops past where rolling left off,
            // so the slowdown always travels forward by a natural distance.
            let cyclesAtStop = (offsetAtStop / totalHeight).rounded(.up)
            let finalOffset = (cyclesAtStop + 2) * totalHeight + targetOffset

            plans.append(SlotPlan(
                spinSpeed: spinSpeed,
                stopStart: stopStart,
                stopDuration: stopDuration,
                offsetAtStop: offsetAtStop,
                finalOffset: finalOffset
            ))
        }

        revealedFlags = Array(repeating: false, count: drinkCount)
        slotPlans = plans
        animationStart = Date()

        // Fire haptics and flip reveal flags at each slot's landing time.
        let start = Date()
        for i in 0..<plans.count {
            let revealAt = plans[i].stopStart + plans[i].stopDuration
            let wait = revealAt - Date().timeIntervalSince(start)
            if wait > 0 {
                try? await Task.sleep(for: .seconds(wait))
            }
            Haptics.medium()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if i < revealedFlags.count { revealedFlags[i] = true }
            }
        }

        Haptics.success()
        allRevealed = true
    }

    /// Continuous reel motion for a slot at a given frame time.
    func slotMotion(index: Int, at date: Date) -> (offset: CGFloat, isSpinning: Bool) {
        guard let start = animationStart, index < slotPlans.count else {
            return (0, false)
        }

        let plan = slotPlans[index]
        let elapsed = date.timeIntervalSince(start)

        if elapsed < plan.stopStart {
            // Rolling at constant speed — modulo wrapping happens in the view.
            return (plan.spinSpeed * CGFloat(elapsed), true)
        } else if elapsed < plan.stopStart + plan.stopDuration {
            // Ease out from rolling speed onto the exact target offset.
            let t = (elapsed - plan.stopStart) / plan.stopDuration
            let eased = 1 - pow(1 - t, 3) // easeOutCubic
            let offset = plan.offsetAtStop + (plan.finalOffset - plan.offsetAtStop) * CGFloat(eased)
            return (offset, true)
        } else {
            return (plan.finalOffset, false)
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
