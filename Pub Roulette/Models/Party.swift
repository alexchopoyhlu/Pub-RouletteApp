import Foundation

enum PartyStatus: String, Codable, Hashable {
    case lobby
    case pubSelection      // Host confirms/edits pubs before starting
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

enum DrinkDistributionMode: String, Codable {
    case random      // Drinks can repeat or not appear
    case oneOfEach   // All selected drinks will appear (cycles if more pubs than drinks)
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
    var pubCount: Int
    var searchRadius: Int
    var searchLatitude: Double?
    var searchLongitude: Double?
    var customPubs: [Pub]
    var teamAssignmentMode: TeamAssignmentMode
    var drinkDistributionMode: DrinkDistributionMode
    var wheelState: WheelState
    var selectedDrinkTypes: [String]
    let createdAt: Date
    var players: [Player]
    var teams: [Team]
    var pubs: [Pub]

    init(
        code: String,
        hostId: String,
        status: PartyStatus = .lobby,
        teamCount: Int = 2,
        pubCount: Int = Constants.defaultPubCount,
        searchRadius: Int = 1000,
        searchLatitude: Double? = nil,
        searchLongitude: Double? = nil,
        customPubs: [Pub] = [],
        teamAssignmentMode: TeamAssignmentMode = .mixed,
        drinkDistributionMode: DrinkDistributionMode = .random,
        wheelState: WheelState = WheelState(),
        selectedDrinkTypes: [String] = Constants.defaultSelectedDrinkTypes,
        createdAt: Date = Date(),
        players: [Player] = [],
        teams: [Team] = [],
        pubs: [Pub] = []
    ) {
        self.code = code
        self.hostId = hostId
        self.status = status
        self.teamCount = teamCount
        self.pubCount = pubCount
        self.searchRadius = searchRadius
        self.searchLatitude = searchLatitude
        self.searchLongitude = searchLongitude
        self.customPubs = customPubs
        self.teamAssignmentMode = teamAssignmentMode
        self.drinkDistributionMode = drinkDistributionMode
        self.wheelState = wheelState
        self.selectedDrinkTypes = selectedDrinkTypes
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
