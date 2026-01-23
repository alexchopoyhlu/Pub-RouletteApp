import Foundation
import SwiftUI

enum Constants {
    static let teamColors: [(name: String, hex: String)] = [
        ("Red", "#E53935"),
        ("Blue", "#1E88E5"),
        ("Green", "#43A047"),
        ("Orange", "#FB8C00"),
        ("Purple", "#8E24AA"),
        ("Teal", "#00897B"),
        ("Pink", "#D81B60"),
        ("Indigo", "#3949AB")
    ]

    static let teamNames: [String] = [
        "Red Roosters",
        "Blue Brewers",
        "Green Guzzlers",
        "Orange Ales",
        "Purple Pints",
        "Teal Tankards",
        "Pink Pilsners",
        "Indigo IPAs"
    ]

    static let drinkTypes: [String] = [
        "Pint",
        "Shot",
        "Cocktail",
        "Wine"
    ]

    static let drinkEmojis: [String: String] = [
        "Pint": "🍺",
        "Shot": "🥃",
        "Cocktail": "🍹",
        "Wine": "🍷"
    ]

    static let drinkIcons: [String: String] = [
        "Pint": "mug.fill",
        "Shot": "wineglass.fill",
        "Cocktail": "tropicaldrink.fill",
        "Wine": "wineglass.fill"
    ]

    static let minSearchRadius: Int = 100
    static let maxSearchRadius: Int = 3000
    static let defaultSearchRadius: Int = 1000

    static let minTeamCount: Int = 2
    static let maxTeamCount: Int = 8

    static let wheelSpinDuration: Double = 3.0
    static let cardFlipDuration: Double = 0.6
    static let slotSpinDuration: Double = 2.0
}
