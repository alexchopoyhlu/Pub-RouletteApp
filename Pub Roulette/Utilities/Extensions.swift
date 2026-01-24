import Foundation
import SwiftUI
import UIKit

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension Array {
    func shuffled(using seed: UInt64) -> [Element] {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return shuffled(using: &generator)
    }
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter.string(from: self)
    }
}

extension String {
    var isValidPartyCode: Bool {
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return self.count == 6 && self.uppercased().unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
}

// MARK: - Custom Font

extension Font {
    /// Bricolage Grotesque SemiBold - use this for all custom text
    static func bricolage(_ style: Font.TextStyle) -> Font {
        let size = textStyleSize(style)
        return bricolage(size: size)
    }

    static func bricolage(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        // We only have SemiBold variant, so we use it regardless of weight
        return .custom("BricolageGrotesque-SemiBold", size: size)
    }

    private static func textStyleSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}

extension UIFont {
    static func bricolage(size: CGFloat) -> UIFont {
        return UIFont(name: "BricolageGrotesque-SemiBold", size: size) ?? .systemFont(ofSize: size, weight: .semibold)
    }
}
