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

    @Option(name: .shortAndLong, help: "Symbol scale within icon (default: 0.38, glass: 0.42)")
    var scale: Double?

    @Option(name: .shortAndLong, help: "Symbol render width in pixels (default: 1024)")
    var width: Int?

    @Option(name: .long, help: "Symbol render height in pixels (default: proportional)")
    var height: Int?

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
            outputDirectory: outputDir
        )

        let outputURL = try IconGenerator.generate(options: options)
        Term.printSuccess("Generated \(outputURL.lastPathComponent)")
        print("  \(Term.dim)\(outputURL.path)\(Term.reset)")
    }
}
