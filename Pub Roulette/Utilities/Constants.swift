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
        "Non-Alcoholic"
    ]

    static let drinkEmojis: [String: String] = [
        "Shot": "🥃",
        "Wine": "🍷",
        "Beer": "🍺",
        "Cocktail": "🍹",
        "Spirits": "🍸",
        "Cider": "🍏",
        "Sparkling": "🥂",
        "Non-Alcoholic": "🧃"
    ]

    static let drinkIcons: [String: String] = [
        "Shot": "wineglass.fill",
        "Wine": "wineglass.fill",
        "Beer": "mug.fill",
        "Cocktail": "tropicaldrink.fill",
        "Spirits": "wineglass.fill",
        "Cider": "leaf.fill",
        "Sparkling": "sparkles",
        "Non-Alcoholic": "drop.fill"
    ]

    static let drinkColors: [String: String] = [
        "Shot": "#3F51B5",      // Indigo
        "Wine": "#8B1538",      // Burgundy
        "Beer": "#C49A20",      // Golden amber
        "Cocktail": "#D81B9C",  // Magenta/Pink
        "Spirits": "#00897B",   // Teal
        "Cider": "#7CB342",     // Apple green
        "Sparkling": "#FFB300", // Gold/Champagne
        "Non-Alcoholic": "#FF7043" // Coral orange
    ]

    static let minSearchRadius: Int = 100
    static let maxSearchRadius: Int = 3000
    static let defaultSearchRadius: Int = 1000

    static let minTeamCount: Int = 2
    static let maxTeamCount: Int = 8

    static let minPubCount: Int = 3
    static let maxPubCount: Int = 10
    static let defaultPubCount: Int = 5

    static let defaultSelectedDrinkTypes: [String] = ["Shot", "Wine", "Beer", "Cocktail"]

    static let wheelSpinDuration: Double = 3.0
    static let cardFlipDuration: Double = 0.6
    static let slotSpinDuration: Double = 2.0

    // MARK: - App Review Demo

    /// Entering this as the player name when creating a party spins up a fully
    /// self-contained demo (bot players + preset pubs) so a single App Review
    /// tester can play through the whole game without a second device.
    static let demoTriggerName: String = "AppleDemo"

    /// Names used for the demo bot players that fill out the party.
    static let demoBotNames: [String] = ["Sam", "Mia", "Jack"]

    /// Preset pubs used in the demo so the game never depends on a real
    /// location search succeeding. Coordinates are real central-London pubs.
    static let demoPubs: [Pub] = [
        Pub(name: "The Churchill Arms", address: "119 Kensington Church St, London", latitude: 51.5074, longitude: -0.1949),
        Pub(name: "Ye Olde Cheshire Cheese", address: "145 Fleet St, London", latitude: 51.5141, longitude: -0.1075),
        Pub(name: "The Mayflower", address: "117 Rotherhithe St, London", latitude: 51.5012, longitude: -0.0531),
        Pub(name: "The Lamb & Flag", address: "33 Rose St, London", latitude: 51.5118, longitude: -0.1257),
        Pub(name: "The Spaniards Inn", address: "Spaniards Rd, London", latitude: 51.5707, longitude: -0.1779),
        Pub(name: "The Prospect of Whitby", address: "57 Wapping Wall, London", latitude: 51.5089, longitude: -0.0498),
        Pub(name: "The Dove", address: "19 Upper Mall, London", latitude: 51.4905, longitude: -0.2356),
        Pub(name: "The George Inn", address: "75-77 Borough High St, London", latitude: 51.5042, longitude: -0.0903),
        Pub(name: "The Blackfriar", address: "174 Queen Victoria St, London", latitude: 51.5121, longitude: -0.1036),
        Pub(name: "The Harp", address: "47 Chandos Pl, London", latitude: 51.5093, longitude: -0.1247)
    ]
}
