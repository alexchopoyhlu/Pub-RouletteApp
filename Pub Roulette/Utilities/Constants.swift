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
        "Shot",
        "Wine",
        "Beer",
        "Cocktail",
        "Spirits",
        "Cider",
        "Sparkling",
        "No-Alcohol"
    ]

    static let drinkEmojis: [String: String] = [
        "Shot": "🥃",
        "Wine": "🍷",
        "Beer": "🍺",
        "Cocktail": "🍹",
        "Spirits": "🍸",
        "Cider": "🍏",
        "Sparkling": "🥂",
        "No-Alcohol": "🧃"
    ]

    static let drinkIcons: [String: String] = [
        "Shot": "wineglass.fill",
        "Wine": "wineglass.fill",
        "Beer": "mug.fill",
        "Cocktail": "tropicaldrink.fill",
        "Spirits": "wineglass.fill",
        "Cider": "leaf.fill",
        "Sparkling": "sparkles",
        "No-Alcohol": "drop.fill"
    ]

    static let drinkColors: [String: String] = [
        "Shot": "#3F51B5",      // Indigo
        "Wine": "#8B1538",      // Burgundy
        "Beer": "#C49A20",      // Golden amber
        "Cocktail": "#D81B9C",  // Magenta/Pink
        "Spirits": "#00897B",   // Teal
        "Cider": "#7CB342",     // Apple green
        "Sparkling": "#FFB300", // Gold/Champagne
        "No-Alcohol": "#FF7043" // Coral orange
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
