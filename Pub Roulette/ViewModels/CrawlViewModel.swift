import Foundation
import SwiftUI

@Observable
final class CrawlViewModel {
    private let partyService = PartyService.shared
    private let locationService = LocationService.shared

    var isSubmitting: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    var party: Party? {
        partyService.currentParty
    }

    var myTeam: Team? {
        partyService.myTeam
    }

    var currentPubIndex: Int {
        myTeam?.currentPubIndex ?? 0
    }

    var orderedPubs: [(pub: Pub, drink: String)] {
        guard let team = myTeam, let party = party else { return [] }

        return team.pubOrder.enumerated().compactMap { (index, pubIndex) in
            guard let pub = party.pubs[safe: pubIndex] else { return nil }
            let drink = team.drinkOrder[safe: index] ?? "Pint"
            return (pub, drink)
        }
    }

    var teamPlayerCount: Int {
        partyService.teamPlayerCount
    }

    var isFinished: Bool {
        myTeam?.isFinished ?? false
    }

    var rankedTeams: [Team] {
        guard let teams = party?.teams else { return [] }
        return teams.sorted { $0.currentPubIndex > $1.currentPubIndex }
    }

    var teamPosition: Int? {
        guard let myTeam = myTeam else { return nil }
        let sorted = rankedTeams
        return sorted.firstIndex(where: { $0.id == myTeam.id }).map { $0 + 1 }
    }

    func submissionCount(for pubIndex: Int) -> Int {
        myTeam?.submissionCount(for: pubIndex) ?? 0
    }

    func hasCurrentPlayerSubmitted(for pubIndex: Int) -> Bool {
        guard let playerId = partyService.currentPlayer?.id else { return false }
        return myTeam?.hasPlayerSubmitted(playerId: playerId, for: pubIndex) ?? false
    }

    func submitEvidence(for pubIndex: Int) async {
        isSubmitting = true
        do {
            try await partyService.submitEvidence(for: pubIndex)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSubmitting = false
    }

    func openInMaps() {
        guard let pub = orderedPubs[safe: currentPubIndex]?.pub else { return }
        locationService.openInMaps(pub: pub)
    }

    func openPubInMaps(_ pub: Pub) {
        locationService.openInMaps(pub: pub)
    }
}
