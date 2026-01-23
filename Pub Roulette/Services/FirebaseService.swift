import Foundation
import FirebaseFirestore

@Observable
final class FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private var partyListener: ListenerRegistration?

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

    private func encodeParty(_ party: Party) throws -> [String: Any] {
        var data: [String: Any] = [
            "hostId": party.hostId,
            "status": party.status.rawValue,
            "teamCount": party.teamCount,
            "searchRadius": party.searchRadius,
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

        return Party(
            code: code,
            hostId: hostId,
            status: status,
            teamCount: teamCount,
            searchRadius: searchRadius,
            searchLatitude: searchLatitude,
            searchLongitude: searchLongitude,
            customPubs: customPubs,
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
}
