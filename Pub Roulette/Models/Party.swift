import Foundation

enum PartyStatus: String, Codable, Hashable {
    case lobby
    case teamAssignment
    case pubReveal
    case drinkReveal
    case active
    case finished
}

struct Party: Codable, Identifiable {
    var id: String { code }
    let code: String
    let hostId: String
    var status: PartyStatus
    var teamCount: Int
    var searchRadius: Int
    var searchLatitude: Double?
    var searchLongitude: Double?
    var customPubs: [Pub]
    let createdAt: Date
    var players: [Player]
    var teams: [Team]
    var pubs: [Pub]

    init(
        code: String,
        hostId: String,
        status: PartyStatus = .lobby,
        teamCount: Int = 2,
        searchRadius: Int = 1000,
        searchLatitude: Double? = nil,
        searchLongitude: Double? = nil,
        customPubs: [Pub] = [],
        createdAt: Date = Date(),
        players: [Player] = [],
        teams: [Team] = [],
        pubs: [Pub] = []
    ) {
        self.code = code
        self.hostId = hostId
        self.status = status
        self.teamCount = teamCount
        self.searchRadius = searchRadius
        self.searchLatitude = searchLatitude
        self.searchLongitude = searchLongitude
        self.customPubs = customPubs
        self.createdAt = createdAt
        self.players = players
        self.teams = teams
        self.pubs = pubs
    }

    static func generateCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}
