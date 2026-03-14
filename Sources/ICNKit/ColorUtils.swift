import AppKit

public struct NamedColor: Sendable {
    public let name: String
    public let hex: String
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8

    public var nsColor: NSColor {
        NSColor(
            srgbRed: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: 1.0
        )
    }
}

public enum ColorUtils {
    public static let namedColors: [NamedColor] = [
        NamedColor(name: "red", hex: "#FF3B30", r: 255, g: 59, b: 48),
        NamedColor(name: "orange", hex: "#FF9500", r: 255, g: 149, b: 0),
        NamedColor(name: "yellow", hex: "#FFCC00", r: 255, g: 204, b: 0),
        NamedColor(name: "green", hex: "#34C759", r: 52, g: 199, b: 89),
        NamedColor(name: "mint", hex: "#00C7BE", r: 0, g: 199, b: 190),
        NamedColor(name: "teal", hex: "#30B0C7", r: 48, g: 176, b: 199),
        NamedColor(name: "cyan", hex: "#32ADE6", r: 50, g: 173, b: 230),
        NamedColor(name: "blue", hex: "#007AFF", r: 0, g: 122, b: 255),
        NamedColor(name: "indigo", hex: "#5856D6", r: 88, g: 86, b: 214),
        NamedColor(name: "purple", hex: "#AF52DE", r: 175, g: 82, b: 222),
        NamedColor(name: "pink", hex: "#FF2D55", r: 255, g: 45, b: 85),
        NamedColor(name: "brown", hex: "#A2845E", r: 162, g: 132, b: 94),
        NamedColor(name: "black", hex: "#000000", r: 0, g: 0, b: 0),
        NamedColor(name: "darkgray", hex: "#1C1C1E", r: 28, g: 28, b: 30),
        NamedColor(name: "gray", hex: "#8E8E93", r: 142, g: 142, b: 147),
        NamedColor(name: "white", hex: "#FFFFFF", r: 255, g: 255, b: 255),
    ]

    public static func parseColor(_ input: String) -> NSColor? {
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmed.isEmpty { return nil }

        // Exact name match
        if let named = namedColors.first(where: { $0.name == trimmed }) {
            return named.nsColor
        }

        // Fuzzy name match
        if let named = namedColors.first(where: {
            $0.name.contains(trimmed) || trimmed.contains($0.name)
        }) {
            return named.nsColor
        }

        // Hex
        return parseHex(trimmed)
    }

    public static func parseHex(_ hex: String) -> NSColor? {
        var h = hex.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h.removeFirst() }

        guard h.count == 6, let value = UInt64(h, radix: 16) else { return nil }

        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0

        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    public static func toDisplayP3String(_ color: NSColor) -> String {
        let c = color.usingColorSpace(.displayP3) ?? color.usingColorSpace(.sRGB) ?? color
        return String(
            format: "display-p3:%.5f,%.5f,%.5f,%.5f",
            c.redComponent, c.greenComponent, c.blueComponent, c.alphaComponent
        )
    }

    public static func relativeLuminance(_ color: NSColor) -> CGFloat {
        guard let srgb = color.usingColorSpace(.sRGB) else { return 0.5 }

        func linearize(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearize(srgb.redComponent)
            + 0.7152 * linearize(srgb.greenComponent)
            + 0.0722 * linearize(srgb.blueComponent)
    }

    public static func autoSymbolColor(forBackground bg: NSColor) -> NSColor {
        relativeLuminance(bg) > 0.4 ? .black : .white
    }

    public static func autoSymbolColorName(forBackground bg: NSColor) -> String {
        relativeLuminance(bg) > 0.4 ? "black" : "white"
    }

    public static func searchColors(_ query: String) -> [NamedColor] {
        let q = query.lowercased()
        return namedColors.filter { $0.name.contains(q) }
    }

    public static func darken(_ color: NSColor, by factor: CGFloat = 0.15) -> NSColor {
        guard let srgb = color.usingColorSpace(.sRGB) else { return color }
        return NSColor(
            srgbRed: max(0, srgb.redComponent * (1 - factor)),
            green: max(0, srgb.greenComponent * (1 - factor)),
            blue: max(0, srgb.blueComponent * (1 - factor)),
            alpha: srgb.alphaComponent
        )
    }

    public static func lighten(_ color: NSColor, by factor: CGFloat = 0.15) -> NSColor {
        guard let srgb = color.usingColorSpace(.sRGB) else { return color }
        return NSColor(
            srgbRed: min(1, srgb.redComponent + (1 - srgb.redComponent) * factor),
            green: min(1, srgb.greenComponent + (1 - srgb.greenComponent) * factor),
            blue: min(1, srgb.blueComponent + (1 - srgb.blueComponent) * factor),
            alpha: srgb.alphaComponent
        )
    }

    public static func toHexString(_ color: NSColor) -> String {
        guard let srgb = color.usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(round(srgb.redComponent * 255))
        let g = Int(round(srgb.greenComponent * 255))
        let b = Int(round(srgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
