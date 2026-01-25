import Foundation
import FirebaseFirestore

@Observable
final class FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private var partyListener: ListenerRegistration?
    private var messageListener: ListenerRegistration?

    private init() {}

    func createParty(_ party: Party) async throws {
        let data = try encodeParty(party)
        try await db.collection("parties").document(party.code).setData(data)
    }

    func getParty(code: String) async throws -> Party? {
        let document = try await db.collection("parties").document(code).getDocument()
        guard document.exists, let data = document.data() else { return nil }
        return try decodeParty(from: data, code: code)
    }

    func updatePartyStatus(code: String, status: PartyStatus) async throws {
        try await db.collection("parties").document(code).updateData([
            "status": status.rawValue
        ])
    }

    func updatePartySettings(code: String, teamCount: Int, searchRadius: Int, searchLatitude: Double?, searchLongitude: Double?) async throws {
        var data: [String: Any] = [
            "teamCount": teamCount,
            "searchRadius": searchRadius
        ]
        if let lat = searchLatitude, let lon = searchLongitude {
            data["searchLatitude"] = lat
            data["searchLongitude"] = lon
        }
        try await db.collection("parties").document(code).updateData(data)
    }

    func updateCustomPubs(code: String, customPubs: [Pub]) async throws {
        let pubsData = customPubs.map { encodePub($0) }
        try await db.collection("parties").document(code).updateData([
            "customPubs": pubsData
        ])
    }

    func addPlayer(to partyCode: String, player: Player) async throws {
        let playerData: [String: Any] = [
            "id": player.id,
            "name": player.name,
            "teamId": player.teamId as Any,
            "joinedAt": Timestamp(date: player.joinedAt)
        ]
        try await db.collection("parties").document(partyCode).updateData([
            "players": FieldValue.arrayUnion([playerData])
        ])
    }

    func updatePlayer(in partyCode: String, player: Player) async throws {
        let party = try await getParty(code: partyCode)
        guard var players = party?.players else { return }

        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
            let playersData = players.map { encodePlayer($0) }
            try await db.collection("parties").document(partyCode).updateData([
                "players": playersData
            ])
        }
    }

    func setTeams(for partyCode: String, teams: [Team]) async throws {
        let teamsData = teams.map { encodeTeam($0) }
        try await db.collection("parties").document(partyCode).updateData([
            "teams": teamsData
        ])
    }

    func updateTeam(in partyCode: String, team: Team) async throws {
        let party = try await getParty(code: partyCode)
        guard var teams = party?.teams else { return }

        if let index = teams.firstIndex(where: { $0.id == team.id }) {
            teams[index] = team
            let teamsData = teams.map { encodeTeam($0) }
            try await db.collection("parties").document(partyCode).updateData([
                "teams": teamsData
            ])
        }
    }

    func setPubs(for partyCode: String, pubs: [Pub]) async throws {
        let pubsData = pubs.map { encodePub($0) }
        try await db.collection("parties").document(partyCode).updateData([
            "pubs": pubsData
        ])
    }

    func updatePlayers(in partyCode: String, players: [Player]) async throws {
        let playersData = players.map { encodePlayer($0) }
        try await db.collection("parties").document(partyCode).updateData([
            "players": playersData
        ])
    }

    func listenToParty(code: String, onChange: @escaping (Party?) -> Void) {
        partyListener?.remove()
        partyListener = db.collection("parties").document(code)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      error == nil else {
                    onChange(nil)
                    return
                }
                let party = try? self.decodeParty(from: data, code: code)
                onChange(party)
            }
    }

    func stopListening() {
        partyListener?.remove()
        partyListener = nil
    }

    func deleteParty(code: String) async throws {
        try await db.collection("parties").document(code).delete()
    }

    // MARK: - Messages

    func sendMessage(to partyCode: String, message: Message) async throws {
        print("FirebaseService: Sending message \(message.id) to parties/\(partyCode)/messages")
        let messageData = encodeMessage(message)
        try await db.collection("parties").document(partyCode)
            .collection("messages").document(message.id).setData(messageData)
        print("FirebaseService: Message sent to Firestore")
    }

    func listenToMessages(partyCode: String, onChange: @escaping ([Message]) -> Void) {
        messageListener?.remove()
        messageListener = db.collection("parties").document(partyCode)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("FirebaseService: Message listener error: \(error)")
                    onChange([])
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("FirebaseService: No documents in snapshot")
                    onChange([])
                    return
                }
                print("FirebaseService: Listener received \(documents.count) documents")
                let messages = documents.compactMap { self.decodeMessage(from: $0.data()) }
                onChange(messages)
            }
    }

    func stopMessageListener() {
        messageListener?.remove()
        messageListener = nil
    }

    private func encodeMessage(_ message: Message) -> [String: Any] {
        var data: [String: Any] = [
            "id": message.id,
            "senderId": message.senderId,
            "senderName": message.senderName,
            "text": message.text,
            "timestamp": Timestamp(date: message.timestamp)
        ]
        if let teamId = message.teamId {
            data["teamId"] = teamId
        }
        return data
    }

    private func decodeMessage(from data: [String: Any]) -> Message? {
        guard let id = data["id"] as? String,
              let senderId = data["senderId"] as? String,
              let senderName = data["senderName"] as? String,
              let text = data["text"] as? String,
              let timestampValue = data["timestamp"] as? Timestamp
        else { return nil }

        return Message(
            id: id,
            senderId: senderId,
            senderName: senderName,
            teamId: data["teamId"] as? String,
            text: text,
            timestamp: timestampValue.dateValue()
        )
    }

    private func encodeParty(_ party: Party) throws -> [String: Any] {
        var data: [String: Any] = [
            "hostId": party.hostId,
            "status": party.status.rawValue,
            "teamCount": party.teamCount,
            "searchRadius": party.searchRadius,
            "teamAssignmentMode": party.teamAssignmentMode.rawValue,
            "wheelState": encodeWheelState(party.wheelState),
            "selectedDrinkTypes": party.selectedDrinkTypes,
            "createdAt": Timestamp(date: party.createdAt),
            "players": party.players.map { encodePlayer($0) },
            "teams": party.teams.map { encodeTeam($0) },
            "pubs": party.pubs.map { encodePub($0) },
            "customPubs": party.customPubs.map { encodePub($0) }
        ]
        if let lat = party.searchLatitude {
            data["searchLatitude"] = lat
        }
        if let lon = party.searchLongitude {
            data["searchLongitude"] = lon
        }
        return data
    }

    private func decodeParty(from data: [String: Any], code: String) throws -> Party {
        guard let hostId = data["hostId"] as? String,
              let statusString = data["status"] as? String,
              let status = PartyStatus(rawValue: statusString),
              let teamCount = data["teamCount"] as? Int,
              let searchRadius = data["searchRadius"] as? Int,
              let createdAtTimestamp = data["createdAt"] as? Timestamp
        else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid party data"])
        }

        let playersData = data["players"] as? [[String: Any]] ?? []
        let players = playersData.compactMap { decodePlayer(from: $0) }

        let teamsData = data["teams"] as? [[String: Any]] ?? []
        let teams = teamsData.compactMap { decodeTeam(from: $0) }

        let pubsData = data["pubs"] as? [[String: Any]] ?? []
        let pubs = pubsData.compactMap { decodePub(from: $0) }

        let customPubsData = data["customPubs"] as? [[String: Any]] ?? []
        let customPubs = customPubsData.compactMap { decodePub(from: $0) }

        let searchLatitude = data["searchLatitude"] as? Double
        let searchLongitude = data["searchLongitude"] as? Double

        let teamAssignmentModeString = data["teamAssignmentMode"] as? String ?? "mixed"
        let teamAssignmentMode = TeamAssignmentMode(rawValue: teamAssignmentModeString) ?? .mixed

        let wheelStateData = data["wheelState"] as? [String: Any]
        let wheelState = wheelStateData.flatMap { decodeWheelState(from: $0) } ?? WheelState()

        let selectedDrinkTypes = data["selectedDrinkTypes"] as? [String] ?? Constants.drinkTypes

        return Party(
            code: code,
            hostId: hostId,
            status: status,
            teamCount: teamCount,
            searchRadius: searchRadius,
            searchLatitude: searchLatitude,
            searchLongitude: searchLongitude,
            customPubs: customPubs,
            teamAssignmentMode: teamAssignmentMode,
            wheelState: wheelState,
            selectedDrinkTypes: selectedDrinkTypes,
            createdAt: createdAtTimestamp.dateValue(),
            players: players,
            teams: teams,
            pubs: pubs
        )
    }

    private func encodePlayer(_ player: Player) -> [String: Any] {
        var data: [String: Any] = [
            "id": player.id,
            "name": player.name,
            "joinedAt": Timestamp(date: player.joinedAt)
        ]
        if let teamId = player.teamId {
            data["teamId"] = teamId
        }
        return data
    }

    private func decodePlayer(from data: [String: Any]) -> Player? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let joinedAtTimestamp = data["joinedAt"] as? Timestamp
        else { return nil }

        return Player(
            id: id,
            name: name,
            teamId: data["teamId"] as? String,
            joinedAt: joinedAtTimestamp.dateValue()
        )
    }

    private func encodeTeam(_ team: Team) -> [String: Any] {
        var data: [String: Any] = [
            "id": team.id,
            "name": team.name,
            "colorHex": team.colorHex,
            "pubOrder": team.pubOrder,
            "drinkOrder": team.drinkOrder,
            "currentPubIndex": team.currentPubIndex,
            "submissions": team.submissions
        ]
        if let finishTime = team.finishTime {
            data["finishTime"] = Timestamp(date: finishTime)
        }
        return data
    }

    private func decodeTeam(from data: [String: Any]) -> Team? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let colorHex = data["colorHex"] as? String
        else { return nil }

        var submissions: [String: [String]] = [:]
        if let submissionsData = data["submissions"] as? [String: [String]] {
            submissions = submissionsData
        }

        return Team(
            id: id,
            name: name,
            colorHex: colorHex,
            pubOrder: data["pubOrder"] as? [Int] ?? [],
            drinkOrder: data["drinkOrder"] as? [String] ?? [],
            currentPubIndex: data["currentPubIndex"] as? Int ?? 0,
            finishTime: (data["finishTime"] as? Timestamp)?.dateValue(),
            submissions: submissions
        )
    }

    private func encodePub(_ pub: Pub) -> [String: Any] {
        return [
            "id": pub.id,
            "name": pub.name,
            "address": pub.address,
            "latitude": pub.latitude,
            "longitude": pub.longitude
        ]
    }

    private func decodePub(from data: [String: Any]) -> Pub? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let address = data["address"] as? String,
              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double
        else { return nil }

        return Pub(
            id: id,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude
        )
    }

    private func encodeWheelState(_ state: WheelState) -> [String: Any] {
        var data: [String: Any] = [
            "rotation": state.rotation,
            "isSpinning": state.isSpinning
        ]
        if let spinStartTime = state.spinStartTime {
            data["spinStartTime"] = Timestamp(date: spinStartTime)
        }
        if let targetRotation = state.targetRotation {
            data["targetRotation"] = targetRotation
        }
        if let selectedPlayerId = state.selectedPlayerId {
            data["selectedPlayerId"] = selectedPlayerId
        }
        return data
    }

    private func decodeWheelState(from data: [String: Any]) -> WheelState? {
        let rotation = data["rotation"] as? Double ?? 0
        let isSpinning = data["isSpinning"] as? Bool ?? false
        let spinStartTime = (data["spinStartTime"] as? Timestamp)?.dateValue()
        let targetRotation = data["targetRotation"] as? Double
        let selectedPlayerId = data["selectedPlayerId"] as? String

        return WheelState(
            rotation: rotation,
            isSpinning: isSpinning,
            spinStartTime: spinStartTime,
            targetRotation: targetRotation,
            selectedPlayerId: selectedPlayerId
        )
    }

    func updateWheelState(code: String, wheelState: WheelState) async throws {
        try await db.collection("parties").document(code).updateData([
            "wheelState": encodeWheelState(wheelState)
        ])
    }

    func updateTeamAssignmentMode(code: String, mode: TeamAssignmentMode) async throws {
        try await db.collection("parties").document(code).updateData([
            "teamAssignmentMode": mode.rawValue
        ])
    }

    func updateSelectedDrinkTypes(code: String, drinkTypes: [String]) async throws {
        try await db.collection("parties").document(code).updateData([
            "selectedDrinkTypes": drinkTypes
        ])
    }
}
