import Foundation

enum PartyStatus: String, Codable, Hashable {
    case lobby
    case teamAssignment
    case pubReveal
    case drinkReveal
    case active
    case finished
}

enum TeamAssignmentMode: String, Codable {
    case sequential
    case mixed
}

struct WheelState: Codable, Equatable {
    var rotation: Double
    var isSpinning: Bool
    var spinStartTime: Date?
    var targetRotation: Double?
    var selectedPlayerId: String?

    init(rotation: Double = 0, isSpinning: Bool = false, spinStartTime: Date? = nil, targetRotation: Double? = nil, selectedPlayerId: String? = nil) {
        self.rotation = rotation
        self.isSpinning = isSpinning
        self.spinStartTime = spinStartTime
        self.targetRotation = targetRotation
        self.selectedPlayerId = selectedPlayerId
    }
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
    var teamAssignmentMode: TeamAssignmentMode
    var wheelState: WheelState
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
        teamAssignmentMode: TeamAssignmentMode = .mixed,
        wheelState: WheelState = WheelState(),
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
        self.teamAssignmentMode = teamAssignmentMode
        self.wheelState = wheelState
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
