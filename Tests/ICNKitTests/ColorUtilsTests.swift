import AppKit
import Testing

@testable import ICNKit

@Suite("Color Utilities")
struct ColorUtilsTests {
    @Test("Parse hex color with hash")
    func parseHexWithHash() {
        let color = ColorUtils.parseHex("#FF3B30")
        #expect(color != nil)
        let srgb = color!.usingColorSpace(.sRGB)!
        #expect(abs(srgb.redComponent - 1.0) < 0.01)
        #expect(abs(srgb.greenComponent - 0.231) < 0.01)
        #expect(abs(srgb.blueComponent - 0.188) < 0.01)
    }

    @Test("Parse hex color without hash")
    func parseHexWithoutHash() {
        let color = ColorUtils.parseHex("007AFF")
        #expect(color != nil)
    }

    @Test("Invalid hex returns nil")
    func invalidHex() {
        #expect(ColorUtils.parseHex("ZZZZZZ") == nil)
        #expect(ColorUtils.parseHex("#12") == nil)
        #expect(ColorUtils.parseHex("") == nil)
    }

    @Test("Parse named color")
    func parseNamedColor() {
        let blue = ColorUtils.parseColor("blue")
        #expect(blue != nil)
        let red = ColorUtils.parseColor("red")
        #expect(red != nil)
        let purple = ColorUtils.parseColor("purple")
        #expect(purple != nil)
    }

    @Test("Parse named color case insensitive")
    func parseNamedCaseInsensitive() {
        let blue = ColorUtils.parseColor("Blue")
        #expect(blue != nil)
        let red = ColorUtils.parseColor("RED")
        #expect(red != nil)
    }

    @Test("Display P3 string format")
    func displayP3String() {
        let color = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let p3 = ColorUtils.toDisplayP3String(color)
        #expect(p3.hasPrefix("display-p3:"))
        #expect(p3.hasSuffix(",1.00000"))
        let components = p3.dropFirst("display-p3:".count).split(separator: ",")
        #expect(components.count == 4)
    }

    @Test("Luminance of black is near zero")
    func luminanceBlack() {
        let black = NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        let lum = ColorUtils.relativeLuminance(black)
        #expect(lum < 0.01)
    }

    @Test("Luminance of white is near one")
    func luminanceWhite() {
        let white = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let lum = ColorUtils.relativeLuminance(white)
        #expect(lum > 0.99)
    }

    @Test("Auto symbol color: white on dark bg")
    func autoWhiteOnDark() {
        let dark = NSColor(srgbRed: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        let name = ColorUtils.autoSymbolColorName(forBackground: dark)
        #expect(name == "white")
    }

    @Test("Auto symbol color: black on light bg")
    func autoBlackOnLight() {
        let light = NSColor(srgbRed: 1, green: 1, blue: 0.8, alpha: 1)
        let name = ColorUtils.autoSymbolColorName(forBackground: light)
        #expect(name == "black")
    }

    @Test("Darken produces darker color")
    func darkenColor() {
        let blue = NSColor(srgbRed: 0, green: 0.478, blue: 1, alpha: 1)
        let darker = ColorUtils.darken(blue)
        let origLum = ColorUtils.relativeLuminance(blue)
        let darkLum = ColorUtils.relativeLuminance(darker)
        #expect(darkLum < origLum)
    }

    @Test("Lighten produces lighter color")
    func lightenColor() {
        let blue = NSColor(srgbRed: 0, green: 0.478, blue: 1, alpha: 1)
        let lighter = ColorUtils.lighten(blue)
        let origLum = ColorUtils.relativeLuminance(blue)
        let lightLum = ColorUtils.relativeLuminance(lighter)
        #expect(lightLum > origLum)
    }

    @Test("Hex string roundtrip")
    func hexRoundtrip() {
        let hex = "#FF9500"
        let color = ColorUtils.parseHex(hex)!
        let result = ColorUtils.toHexString(color)
        #expect(result == hex)
    }

    @Test("Search colors")
    func searchColors() {
        let results = ColorUtils.searchColors("gr")
        #expect(results.contains(where: { $0.name == "green" }))
        #expect(results.contains(where: { $0.name == "gray" }))
    }

    @Test("Named colors list is complete")
    func namedColorsCount() {
        #expect(ColorUtils.namedColors.count == 16)
    }
}
