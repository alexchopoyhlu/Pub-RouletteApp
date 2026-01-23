import Foundation
import SwiftUI

struct Team: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let colorHex: String
    var pubOrder: [Int]
    var drinkOrder: [String]
    var currentPubIndex: Int
    var finishTime: Date?
    var submissions: [String: [String]]

    init(
        id: String = UUID().uuidString,
        name: String,
        colorHex: String,
        pubOrder: [Int] = [],
        drinkOrder: [String] = [],
        currentPubIndex: Int = 0,
        finishTime: Date? = nil,
        submissions: [String: [String]] = [:]
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.pubOrder = pubOrder
        self.drinkOrder = drinkOrder
        self.currentPubIndex = currentPubIndex
        self.finishTime = finishTime
        self.submissions = submissions
    }

    func submissionCount(for pubIndex: Int) -> Int {
        submissions[String(pubIndex)]?.count ?? 0
    }

    func hasPlayerSubmitted(playerId: String, for pubIndex: Int) -> Bool {
        submissions[String(pubIndex)]?.contains(playerId) ?? false
    }

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }

    var isFinished: Bool {
        finishTime != nil
    }
}
