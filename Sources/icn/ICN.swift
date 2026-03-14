import AppKit
import ArgumentParser
import ICNKit

@main
struct ICN: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "icn",
        abstract: "Generate .icon files from SF Symbols for Apple platforms",
        version: "0.1.0"
    )

    @Argument(help: "SF Symbol name (e.g. swift, heart.fill)")
    var symbol: String?

    @Option(name: .shortAndLong, help: "Output file name (default: AppIcon)")
    var name: String?

    @Option(name: .shortAndLong, help: "Background color — hex (#FF0000) or name (red, blue...)")
    var color: String?

    @Option(name: .shortAndLong, help: "Fill style: solid, gradient, linear (default: gradient)")
    var fill: String?

    @Option(name: .long, help: "Symbol foreground color — hex or name (default: auto)")
    var symbolColor: String?

    @Flag(name: .shortAndLong, help: "Enable glass effect")
    var glass: Bool = false

    @Option(name: .shortAndLong, help: "Symbol scale within icon (default: 0.57, glass: 0.63)")
    var scale: Double?

    @Option(name: .shortAndLong, help: "Symbol render width in pixels (default: 1024)")
    var width: Int?

    @Option(name: .long, help: "Symbol render height in pixels (default: proportional)")
    var height: Int?

    @Flag(name: .long, help: "Also export composited PNG preview")
    var png: Bool = false

    @Option(name: .long, help: "Target platform: ios, macos, watchos (default: ios)")
    var platform: String?

    @Option(name: .long, help: "Rendition: default, dark, tinted-dark (default: default)")
    var rendition: String?

    @Option(name: .shortAndLong, help: "Output directory (default: current)")
    var output: String?

    mutating func run() throws {
        if symbol == nil && isatty(STDIN_FILENO) != 0 {
            try Interactive.run()
            return
        }

        guard let symbolName = symbol else {
            throw CleanExit.helpRequest(self)
        }

        // Parse colors
        let bgColor = color.flatMap { ColorUtils.parseColor($0) }
            ?? NSColor(srgbRed: 0, green: 0.478, blue: 1, alpha: 1) // Apple blue

        let fgColor = symbolColor.flatMap { ColorUtils.parseColor($0) }

        let fillStyle: FillStyle
        switch fill?.lowercased() {
        case "solid": fillStyle = .solid
        case "linear": fillStyle = .linear
        default: fillStyle = .gradient
        }

        let outputDir = output ?? FileManager.default.currentDirectoryPath

        let options = GeneratorOptions(
            fileName: name ?? "AppIcon",
            symbolName: symbolName,
            backgroundColor: bgColor,
            fillStyle: fillStyle,
            symbolColor: fgColor,
            glass: glass,
            symbolScale: scale,
            targetWidth: width,
            targetHeight: height,
            exportPNG: png,
            platform: parsePlatform(platform),
            rendition: parseRendition(rendition),
            outputDirectory: outputDir
        )

        let outputURL = try IconGenerator.generate(options: options)
        Term.printSuccess("Generated \(outputURL.lastPathComponent)")
        print("  \(Term.dim)\(outputURL.path)\(Term.reset)")
        if png {
            let pngPath = URL(fileURLWithPath: outputDir)
                .appendingPathComponent("\(name ?? "AppIcon").png").path
            let method = ICTool.isAvailable ? "ictool" : "built-in"
            Term.printSuccess("Exported \(name ?? "AppIcon").png \(Term.dim)(\(method))\(Term.reset)")
            print("  \(Term.dim)\(pngPath)\(Term.reset)")
        }
    }

    private func parsePlatform(_ input: String?) -> Platform {
        switch input?.lowercased() {
        case "macos", "mac": return .macOS
        case "watchos", "watch": return .watchOS
        default: return .iOS
        }
    }

    private func parseRendition(_ input: String?) -> Rendition {
        switch input?.lowercased() {
        case "dark": return .dark
        case "tinted-dark", "tinteddark", "tinted": return .tintedDark
        default: return .default
        }
    }
}
