import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let senderId: String
    let senderName: String
    let teamId: String?
    let text: String
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        senderId: String,
        senderName: String,
        teamId: String? = nil,
        text: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.teamId = teamId
        self.text = text
        self.timestamp = timestamp
    }
}
