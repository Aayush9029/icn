import Darwin
import ICNKit

enum Term {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    static let green = "\u{001B}[32m"
    static let red = "\u{001B}[31m"
    static let yellow = "\u{001B}[33m"
    static let cyan = "\u{001B}[36m"

    static func bg24(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> String {
        "\u{001B}[48;2;\(r);\(g);\(b)m"
    }

    static func fg24(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> String {
        "\u{001B}[38;2;\(r);\(g);\(b)m"
    }

    static func colorBlock(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> String {
        "\(bg24(r, g, b))  \(reset)"
    }

    static func prompt(_ message: String, default defaultValue: String? = nil) -> String {
        if let defaultValue {
            print("  \(message) \(dim)[\(defaultValue)]\(reset): ", terminator: "")
        } else {
            print("  \(message): ", terminator: "")
        }
        fflush(stdout)
        guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
            return defaultValue ?? ""
        }
        return input.isEmpty ? (defaultValue ?? "") : input
    }

    static func printHeader() {
        print()
        print("  \(bold)\(cyan)icn\(reset) \(dim)— SF Symbol Icon Generator\(reset)")
        print()
    }

    static func printSuccess(_ message: String) {
        print("  \(green)✓\(reset) \(message)")
    }

    static func printError(_ message: String) {
        print("  \(red)✗\(reset) \(message)")
    }

    static func printColorPalette() {
        let colors = ColorUtils.namedColors
        let columns = 4
        let colWidth = 16

        print()
        for (i, color) in colors.enumerated() {
            let block = colorBlock(color.r, color.g, color.b)
            let padded = color.name.padding(toLength: colWidth - 5, withPad: " ", startingAt: 0)
            print("  \(block) \(padded)", terminator: "")
            if (i + 1) % columns == 0 {
                print()
            }
        }
        if colors.count % columns != 0 { print() }
        print()
    }
}
