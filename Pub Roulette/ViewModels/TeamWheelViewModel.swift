import Foundation
import SwiftUI
import UIKit

@Observable
final class TeamWheelViewModel {
    private let partyService = PartyService.shared
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    // Local animation state
    private var animationTimer: Timer?
    private var spinStartTime: Date?
    private var spinDuration: Double = 4.0
    private var startRotation: Double = 0
    private var targetRotation: Double = 0

    // Segment colors - keyed by player ID to maintain consistency
    private var playerColors: [String: Color] = [:]

    var party: Party? {
        partyService.currentParty
    }

    var isHost: Bool {
        partyService.isHost
    }

    var teams: [Team] {
        party?.teams ?? []
    }

    var unassignedPlayers: [Player] {
        party?.players.filter { $0.teamId == nil } ?? []
    }

    var allPlayersAssigned: Bool {
        unassignedPlayers.isEmpty
    }

    var isSpinning: Bool {
        party?.wheelState.isSpinning ?? false
    }

    var wheelState: WheelState {
        party?.wheelState ?? WheelState()
    }

    var teamAssignmentMode: TeamAssignmentMode {
        party?.teamAssignmentMode ?? .mixed
    }

    // The rotation value to display (animated locally)
    var displayRotation: Double = 0

    // Colors for the current unassigned players
    var segmentColors: [Color] {
        unassignedPlayers.map { player in
            if let color = playerColors[player.id] {
                return color
            }
            // Generate a new color for this player
            let newColor = generateColorForPlayer(player.id)
            playerColors[player.id] = newColor
            return newColor
        }
    }

    // Track last observed wheel state to detect changes
    private var lastObservedSpinStartTime: Date?

    init() {
        hapticGenerator.prepare()
        // Initialize colors for all players
        if let players = partyService.currentParty?.players {
            for player in players {
                playerColors[player.id] = generateColorForPlayer(player.id)
            }
        }

        // Set initial display rotation from wheel state
        if let party = partyService.currentParty {
            displayRotation = party.wheelState.rotation
        }
    }

    // Call this from the view's onChange of wheelState to sync non-host animations
    func syncWheelState() {
        guard let wheelState = party?.wheelState else { return }

        // If a new spin started (for non-host players)
        if wheelState.isSpinning,
           let spinStartTime = wheelState.spinStartTime,
           let targetRotation = wheelState.targetRotation,
           let selectedPlayerId = wheelState.selectedPlayerId,
           spinStartTime != lastObservedSpinStartTime {

            lastObservedSpinStartTime = spinStartTime

            // Find the selected player
            if let selectedPlayer = party?.players.first(where: { $0.id == selectedPlayerId }) {
                // Start animation from current display rotation
                startSpinAnimation(to: targetRotation, selectedPlayer: selectedPlayer)
            }
        }
    }

    private func generateColorForPlayer(_ playerId: String) -> Color {
        let colors: [Color] = [
            Color(hex: "#E53935") ?? .red,
            Color(hex: "#1E88E5") ?? .blue,
            Color(hex: "#43A047") ?? .green,
            Color(hex: "#FDD835") ?? .yellow,
            Color(hex: "#8E24AA") ?? .purple,
            Color(hex: "#FB8C00") ?? .orange,
            Color(hex: "#00897B") ?? .teal,
            Color(hex: "#D81B60") ?? .pink
        ]
        // Use hash of player ID to get consistent color
        let hash = abs(playerId.hashValue)
        return colors[hash % colors.count]
    }

    func playersInTeam(_ team: Team) -> [Player] {
        party?.players.filter { $0.teamId == team.id } ?? []
    }

    func triggerHaptic() {
        hapticGenerator.impactOccurred()
    }

    func spinWheel() async {
        guard !isSpinning, !unassignedPlayers.isEmpty, isHost else { return }

        let players = unassignedPlayers
        guard !players.isEmpty else { return }

        // Select random player
        let selectedIndex = Int.random(in: 0..<players.count)
        let selectedPlayer = players[selectedIndex]

        // Calculate target rotation to land in center of selected player's segment
        let segmentSize = 360.0 / Double(players.count)
        // Pointer is at top (-90 degrees), we want segment center at top
        // Segment i starts at (i * segmentSize - 90) degrees
        // To put segment center at top, rotate so that (i * segmentSize + segmentSize/2) aligns with 0
        let segmentCenter = Double(selectedIndex) * segmentSize + segmentSize / 2
        // We need to rotate the wheel so this segment is at the top (270 degrees / -90 degrees)
        // Current rotation + X = ... such that segmentCenter ends up at 270 mod 360
        // We want: (currentRotation + extraRotation + segmentCenter) mod 360 = 270
        // So extraRotation = 270 - segmentCenter - currentRotation (mod 360) + N*360 for spins

        let currentRotation = displayRotation.truncatingRemainder(dividingBy: 360)
        var targetAngle = 270 - segmentCenter - currentRotation
        // Normalize to positive
        while targetAngle < 0 {
            targetAngle += 360
        }
        // Add random spins (5-8 full rotations for drama)
        let extraSpins = Double.random(in: 5...8)
        let totalRotation = displayRotation + targetAngle + extraSpins * 360

        // Add slight randomness within segment to make it more natural (but not too close to edges)
        let wobble = Double.random(in: -segmentSize * 0.2...segmentSize * 0.2)
        let finalRotation = totalRotation + wobble

        // Update Firebase state
        var newState = WheelState(
            rotation: finalRotation,
            isSpinning: true,
            spinStartTime: Date(),
            targetRotation: finalRotation,
            selectedPlayerId: selectedPlayer.id
        )

        do {
            try await partyService.updateWheelState(newState)
            // Start local animation
            startSpinAnimation(to: finalRotation, selectedPlayer: selectedPlayer)
        } catch {
            print("Error starting spin: \(error)")
        }
    }

    private func startSpinAnimation(to targetRotation: Double, selectedPlayer: Player) {
        self.startRotation = displayRotation
        self.targetRotation = targetRotation
        self.spinStartTime = Date()
        self.spinDuration = 4.0

        // Cancel any existing timer
        animationTimer?.invalidate()

        let shouldAssign = isHost  // Only host assigns players

        // Use a timer for smooth animation that we can track for haptics
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            guard let startTime = self.spinStartTime else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / self.spinDuration, 1.0)

            // Ease out cubic for satisfying deceleration
            let easedProgress = 1 - pow(1 - progress, 3)

            let previousRotation = self.displayRotation
            self.displayRotation = self.startRotation + (self.targetRotation - self.startRotation) * easedProgress

            // Check for border crossing for haptic
            if self.unassignedPlayers.count > 0 {
                let segmentSize = 360.0 / Double(self.unassignedPlayers.count)
                let prevSegment = Int((previousRotation.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / segmentSize)
                let currSegment = Int((self.displayRotation.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / segmentSize)
                if prevSegment != currSegment {
                    self.triggerHaptic()
                }
            }

            if progress >= 1.0 {
                timer.invalidate()
                self.animationTimer = nil
                // Animation complete, only host assigns player
                if shouldAssign {
                    Task {
                        await self.assignSelectedPlayer(selectedPlayer)
                    }
                }
            }
        }
    }

    private func assignSelectedPlayer(_ player: Player) async {
        // Determine which team to assign based on mode
        guard let party = party else { return }

        let teamId: String
        if teamAssignmentMode == .sequential {
            // Fill teams sequentially
            teamId = selectTeamSequential()
        } else {
            // Mixed - distribute evenly (round robin style)
            teamId = selectTeamMixed()
        }

        do {
            try await partyService.assignPlayerToTeam(player: player, teamId: teamId)

            // Reset wheel state
            var resetState = WheelState(
                rotation: displayRotation,
                isSpinning: false,
                spinStartTime: nil,
                targetRotation: nil,
                selectedPlayerId: nil
            )
            try await partyService.updateWheelState(resetState)
        } catch {
            print("Error assigning player: \(error)")
        }
    }

    private func selectTeamSequential() -> String {
        guard let party = party else { return teams.first?.id ?? "" }

        // Find first team that isn't full
        let playersPerTeam = Int(ceil(Double(party.players.count) / Double(teams.count)))

        for team in teams {
            let count = party.players.filter { $0.teamId == team.id }.count
            if count < playersPerTeam {
                return team.id
            }
        }
        return teams.first?.id ?? ""
    }

    private func selectTeamMixed() -> String {
        guard let party = party else { return teams.first?.id ?? "" }

        // Find team with fewest players
        let teamCounts = teams.map { team in
            (team.id, party.players.filter { $0.teamId == team.id }.count)
        }

        let minCount = teamCounts.map { $0.1 }.min() ?? 0
        let eligibleTeams = teamCounts.filter { $0.1 == minCount }.map { $0.0 }

        // Pick first eligible team (deterministic order)
        return eligibleTeams.first ?? teams.first?.id ?? ""
    }

    func proceedToPubReveal() async {
        do {
            try await partyService.finishTeamAssignment()
            try await partyService.assignPubOrdersAndDrinks()
        } catch {
            print("Error proceeding to pub reveal: \(error)")
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
