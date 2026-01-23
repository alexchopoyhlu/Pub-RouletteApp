import Foundation

struct Player: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    var teamId: String?
    let joinedAt: Date

    init(id: String = UUID().uuidString, name: String, teamId: String? = nil, joinedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.teamId = teamId
        self.joinedAt = joinedAt
    }
}
