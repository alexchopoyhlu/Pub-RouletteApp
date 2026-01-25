import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let senderId: String
    let senderName: String
    let teamId: String?
    let text: String
    let timestamp: Date
    let isSystemMessage: Bool

    init(
        id: String = UUID().uuidString,
        senderId: String,
        senderName: String,
        teamId: String? = nil,
        text: String,
        timestamp: Date = Date(),
        isSystemMessage: Bool = false
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.teamId = teamId
        self.text = text
        self.timestamp = timestamp
        self.isSystemMessage = isSystemMessage
    }

    /// Create a system message (for events like player leaving, team completing pub, etc.)
    static func system(_ text: String, teamId: String? = nil) -> Message {
        Message(
            senderId: "system",
            senderName: "System",
            teamId: teamId,
            text: text,
            isSystemMessage: true
        )
    }
}
