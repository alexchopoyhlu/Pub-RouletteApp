import Foundation
import CoreLocation

@Observable
final class PartyService {
    static let shared = PartyService()

    private let firebaseService = FirebaseService.shared
    private let locationService = LocationService.shared

    var currentParty: Party?
    var currentPlayer: Player?
    var isHost: Bool = false
    var error: Error?
    var messages: [Message] = []
    private var isMessageListenerActive = false

    private init() {}

    var myTeam: Team? {
        guard let teamId = currentPlayer?.teamId,
              let teams = currentParty?.teams else { return nil }
        return teams.first { $0.id == teamId }
    }

    func createParty(hostName: String) async throws -> Party {
        let code = Party.generateCode()
        let hostId = UUID().uuidString
        let host = Player(id: hostId, name: hostName)

        let party = Party(
            code: code,
            hostId: hostId,
            players: [host]
        )

        try await firebaseService.createParty(party)

        currentParty = party
        currentPlayer = host
        isHost = true

        startListening(to: code)

        return party
    }

    func joinParty(code: String, playerName: String) async throws -> Party {
        guard let party = try await firebaseService.getParty(code: code.uppercased()) else {
            throw PartyError.partyNotFound
        }

        guard party.status == .lobby else {
            throw PartyError.gameAlreadyStarted
        }

        if let existingPlayer = party.players.first(where: { $0.name.lowercased() == playerName.lowercased() }) {
            currentParty = party
            currentPlayer = existingPlayer
            isHost = existingPlayer.id == party.hostId
            startListening(to: party.code)
            return party
        }

        let newPlayer = Player(name: playerName)
        try await firebaseService.addPlayer(to: party.code, player: newPlayer)

        currentPlayer = newPlayer
        currentParty = party
        isHost = false

        startListening(to: party.code)

        return party
    }

    func updateSettings(teamCount: Int, pubCount: Int, searchRadius: Int, searchLatitude: Double? = nil, searchLongitude: Double? = nil) async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.updatePartySettings(code: code, teamCount: teamCount, pubCount: pubCount, searchRadius: searchRadius, searchLatitude: searchLatitude, searchLongitude: searchLongitude)
    }

    func updateTeamAssignmentMode(_ mode: TeamAssignmentMode) async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.updateTeamAssignmentMode(code: code, mode: mode)
    }

    func updateDrinkDistributionMode(_ mode: DrinkDistributionMode) async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.updateDrinkDistributionMode(code: code, mode: mode)
    }

    func updateWheelState(_ state: WheelState) async throws {
        guard let code = currentParty?.code else { return }
        try await firebaseService.updateWheelState(code: code, wheelState: state)
    }

    func updateCustomPubs(_ pubs: [Pub]) async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.updateCustomPubs(code: code, customPubs: pubs)
    }

    func updateSelectedDrinkTypes(_ drinkTypes: [String]) async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.updateSelectedDrinkTypes(code: code, drinkTypes: drinkTypes)
    }

    func startGame() async throws {
        guard let party = currentParty, isHost else { return }

        let searchLocation: CLLocation?
        if let lat = party.searchLatitude, let lon = party.searchLongitude {
            searchLocation = CLLocation(latitude: lat, longitude: lon)
        } else {
            searchLocation = nil
        }

        // Get pubs from location search
        let searchedPubs = try await locationService.searchNearbyPubs(radius: party.searchRadius, at: searchLocation)

        // Combine searched pubs with custom pubs, removing duplicates
        var allPubs = searchedPubs
        for customPub in party.customPubs {
            if !allPubs.contains(where: { $0.name == customPub.name }) {
                allPubs.append(customPub)
            }
        }

        guard allPubs.count >= party.pubCount else {
            throw PartyError.notEnoughPubs
        }

        let selectedPubs = Array(allPubs.shuffled().prefix(party.pubCount))
        try await firebaseService.setPubs(for: party.code, pubs: selectedPubs)

        // Go to pub selection for host to confirm
        try await firebaseService.updatePartyStatus(code: party.code, status: .pubSelection)
    }

    func confirmPubSelection() async throws {
        guard let party = currentParty, isHost else { return }

        // Create teams and proceed to team assignment
        let teams = createTeams(count: party.teamCount)
        try await firebaseService.setTeams(for: party.code, teams: teams)

        try await firebaseService.updatePartyStatus(code: party.code, status: .teamAssignment)
    }

    func updatePubs(_ pubs: [Pub]) async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.setPubs(for: code, pubs: pubs)
    }

    func searchMorePubs() async throws -> [Pub] {
        guard let party = currentParty else { return [] }

        let searchLocation: CLLocation?
        if let lat = party.searchLatitude, let lon = party.searchLongitude {
            searchLocation = CLLocation(latitude: lat, longitude: lon)
        } else {
            searchLocation = nil
        }

        return try await locationService.searchNearbyPubs(radius: party.searchRadius, at: searchLocation)
    }

    private func createTeams(count: Int) -> [Team] {
        return (0..<count).map { index in
            Team(
                name: Constants.teamNames[index],
                colorHex: Constants.teamColors[index].hex
            )
        }
    }

    func assignPlayerToTeam(player: Player, teamId: String) async throws {
        guard let code = currentParty?.code else { return }

        var updatedPlayer = player
        updatedPlayer.teamId = teamId
        try await firebaseService.updatePlayer(in: code, player: updatedPlayer)

        if player.id == currentPlayer?.id {
            currentPlayer?.teamId = teamId
        }
    }

    func updateTeam(_ team: Team) async throws {
        guard let code = currentParty?.code else { return }
        try await firebaseService.updateTeam(in: code, team: team)
    }

    func finishTeamAssignment() async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.updatePartyStatus(code: code, status: .pubReveal)
    }

    func assignPubOrdersAndDrinks() async throws {
        guard let party = currentParty, isHost else { return }

        var updatedTeams = party.teams
        let pubCount = party.pubs.count

        // Pick a random final pub that all teams will end at
        let finalPubIndex = Int.random(in: 0..<pubCount)

        // Use selected drink types or fall back to all types
        let availableDrinks = party.selectedDrinkTypes.isEmpty ? Constants.drinkTypes : party.selectedDrinkTypes

        for i in 0..<updatedTeams.count {
            // Get all pub indices except the final one
            var pubIndices = Array(0..<pubCount).filter { $0 != finalPubIndex }
            pubIndices.shuffle()
            // Add the final pub at the end so all teams end at the same place
            pubIndices.append(finalPubIndex)
            updatedTeams[i].pubOrder = pubIndices

            // Assign drinks based on distribution mode
            switch party.drinkDistributionMode {
            case .random:
                // Random: drinks can repeat or not appear
                updatedTeams[i].drinkOrder = (0..<pubCount).map { _ in
                    availableDrinks.randomElement() ?? "Beer"
                }
            case .oneOfEach:
                // One of each: cycle through all selected drinks, ensuring each appears
                var shuffledDrinks = availableDrinks.shuffled()
                var drinkOrder: [String] = []
                for j in 0..<pubCount {
                    // Cycle through drinks, reshuffling when we've used them all
                    if j % availableDrinks.count == 0 && j > 0 {
                        shuffledDrinks = availableDrinks.shuffled()
                    }
                    drinkOrder.append(shuffledDrinks[j % availableDrinks.count])
                }
                updatedTeams[i].drinkOrder = drinkOrder
            }
        }

        try await firebaseService.setTeams(for: party.code, teams: updatedTeams)
    }

    func finishPubReveal() async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.updatePartyStatus(code: code, status: .drinkReveal)
    }

    func finishDrinkReveal() async throws {
        guard let code = currentParty?.code, isHost else { return }
        try await firebaseService.updatePartyStatus(code: code, status: .active)
    }

    func submitEvidence(for pubIndex: Int) async throws {
        guard let party = currentParty,
              let player = currentPlayer,
              let teamId = player.teamId,
              var team = party.teams.first(where: { $0.id == teamId })
        else { return }

        let pubKey = String(pubIndex)
        var currentSubmissions = team.submissions[pubKey] ?? []

        guard !currentSubmissions.contains(player.id) else { return }

        currentSubmissions.append(player.id)
        team.submissions[pubKey] = currentSubmissions

        let teamPlayers = party.players.filter { $0.teamId == teamId }
        let allSubmitted = teamPlayers.allSatisfy { currentSubmissions.contains($0.id) }

        if allSubmitted {
            // Record pub completion time
            let completionTime = Date()
            team.pubCompletionTimes[pubKey] = completionTime
            team.currentPubIndex = pubIndex + 1

            // Get pub name for the system message
            let pubOrderIndex = team.pubOrder[safe: pubIndex]
            let pubName = pubOrderIndex.flatMap { party.pubs[safe: $0]?.name } ?? "Pub \(pubIndex + 1)"

            if team.currentPubIndex >= team.pubOrder.count {
                team.finishTime = completionTime
                // Team finished all pubs!
                Task {
                    await sendSystemMessage("\(team.name) has finished the crawl! 🎉", teamId: team.id)
                }
            } else {
                // Team completed a pub
                Task {
                    await sendSystemMessage("\(team.name) completed \(pubName)", teamId: team.id)
                }
            }
        }

        try await firebaseService.updateTeam(in: party.code, team: team)

        // When the first team finishes, end the game for everyone
        if team.finishTime != nil {
            try await firebaseService.updatePartyStatus(code: party.code, status: .finished)
        }
    }

    var teamPlayerCount: Int {
        guard let party = currentParty,
              let teamId = currentPlayer?.teamId else { return 0 }
        return party.players.filter { $0.teamId == teamId }.count
    }

    func startListening(to code: String) {
        firebaseService.listenToParty(code: code) { [weak self] party in
            self?.currentParty = party
            if let party = party, let playerId = self?.currentPlayer?.id {
                self?.currentPlayer = party.players.first { $0.id == playerId }
            }
        }
    }

    func stopListening() {
        firebaseService.stopListening()
    }

    // MARK: - Messages

    func sendMessage(text: String) async throws {
        print("PartyService: sendMessage called with text: \(text)")
        guard let party = currentParty,
              let player = currentPlayer,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            print("PartyService: sendMessage guard failed - party: \(currentParty != nil), player: \(currentPlayer != nil)")
            return
        }

        let message = Message(
            senderId: player.id,
            senderName: player.name,
            teamId: player.teamId,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        print("PartyService: Sending message to party \(party.code)")
        try await firebaseService.sendMessage(to: party.code, message: message)
        print("PartyService: Message sent successfully")
    }

    func sendSystemMessage(_ text: String, teamId: String? = nil) async {
        guard let party = currentParty else { return }

        let message = Message.system(text, teamId: teamId)
        try? await firebaseService.sendMessage(to: party.code, message: message)
    }

    func startMessageListener() {
        print("PartyService: startMessageListener called")
        print("PartyService: currentParty?.code = \(currentParty?.code ?? "nil")")
        print("PartyService: isMessageListenerActive = \(isMessageListenerActive)")
        guard let code = currentParty?.code,
              !isMessageListenerActive else {
            print("PartyService: Guard failed, not starting listener")
            return
        }
        isMessageListenerActive = true
        print("PartyService: Starting listener for code \(code)")
        firebaseService.listenToMessages(partyCode: code) { [weak self] messages in
            print("PartyService: Received \(messages.count) messages from listener")
            DispatchQueue.main.async {
                self?.messages = messages
            }
        }
    }

    func stopMessageListener() {
        print("PartyService: stopMessageListener called")
        firebaseService.stopMessageListener()
        messages = []
        isMessageListenerActive = false
    }

    func leaveParty() async {
        // Send system message before leaving
        if let player = currentPlayer {
            await sendSystemMessage("\(player.name) left the game")

            // Remove player from Firebase
            if let code = currentParty?.code {
                try? await firebaseService.removePlayer(from: code, playerId: player.id)
            }
        }

        stopListening()
        stopMessageListener()
        currentParty = nil
        currentPlayer = nil
        isHost = false
    }
}

enum PartyError: LocalizedError {
    case partyNotFound
    case gameAlreadyStarted
    case notEnoughPubs
    case invalidCode

    var errorDescription: String? {
        switch self {
        case .partyNotFound:
            return "Party not found. Check the code and try again."
        case .gameAlreadyStarted:
            return "This game has already started."
        case .notEnoughPubs:
            return "Not enough pubs found nearby. Try increasing the search radius."
        case .invalidCode:
            return "Invalid party code format."
        }
    }
}
