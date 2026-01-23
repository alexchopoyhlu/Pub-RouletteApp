import Foundation
import SwiftUI

@Observable
final class TeamWheelViewModel {
    private let partyService = PartyService.shared

    var currentPlayerIndex: Int = 0
    var isSpinning: Bool = false
    var wheelRotation: Double = 0
    var targetTeamIndex: Int?
    var assignmentComplete: Bool = false

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

    var currentPlayer: Player? {
        guard currentPlayerIndex < unassignedPlayers.count else { return nil }
        return unassignedPlayers[currentPlayerIndex]
    }

    var allPlayersAssigned: Bool {
        unassignedPlayers.isEmpty
    }

    func spinWheel() async {
        guard let player = currentPlayer, !isSpinning else { return }

        isSpinning = true

        let targetIndex = selectTeamForPlayer()
        targetTeamIndex = targetIndex

        let segmentAngle = 360.0 / Double(teams.count)
        let targetAngle = segmentAngle * Double(targetIndex) + segmentAngle / 2
        let spins = 5.0
        let finalRotation = spins * 360 + (360 - targetAngle)

        withAnimation(.easeOut(duration: Constants.wheelSpinDuration)) {
            wheelRotation += finalRotation
        }

        try? await Task.sleep(for: .seconds(Constants.wheelSpinDuration + 0.5))

        if let teamId = teams[safe: targetIndex]?.id {
            do {
                try await partyService.assignPlayerToTeam(player: player, teamId: teamId)
            } catch {
                print("Error assigning player: \(error)")
            }
        }

        isSpinning = false
        targetTeamIndex = nil

        if allPlayersAssigned {
            assignmentComplete = true
        }
    }

    private func selectTeamForPlayer() -> Int {
        guard let party = party else { return 0 }

        let teamCounts = teams.map { team in
            party.players.filter { $0.teamId == team.id }.count
        }

        let minCount = teamCounts.min() ?? 0
        let eligibleTeams = teamCounts.enumerated().filter { $0.element == minCount }.map { $0.offset }

        return eligibleTeams.randomElement() ?? 0
    }

func proceedToPubReveal() async {
        do {
            print("TeamWheelVM: Starting proceedToPubReveal")
            try await partyService.finishTeamAssignment()
            print("TeamWheelVM: Finished team assignment")
            try await partyService.assignPubOrdersAndDrinks()
            print("TeamWheelVM: Assigned pub orders and drinks")
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
