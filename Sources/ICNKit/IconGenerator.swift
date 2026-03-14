import AppKit
import Foundation

public enum IconGeneratorError: Error, CustomStringConvertible {
    case outputDirectoryCreationFailed(String)
    case jsonWriteFailed(String)
    case pngWriteFailed(String)

    public var description: String {
        switch self {
        case .outputDirectoryCreationFailed(let path):
            return "Failed to create output directory: \(path)"
        case .jsonWriteFailed(let detail):
            return "Failed to write icon.json: \(detail)"
        case .pngWriteFailed(let detail):
            return "Failed to write Container.png: \(detail)"
        }
    }
}

public struct GeneratorOptions: Sendable {
    public var fileName: String
    public var symbolName: String
    public var backgroundColor: NSColor
    public var fillStyle: FillStyle
    public var gradientEndColor: NSColor?
    public var symbolColor: NSColor?
    public var glass: Bool
    public var symbolScale: Double?
    public var targetWidth: Int?
    public var targetHeight: Int?
    public var exportPNG: Bool
    public var outputDirectory: String

    public init(
        fileName: String = "AppIcon",
        symbolName: String,
        backgroundColor: NSColor = NSColor(srgbRed: 0, green: 0.478, blue: 1, alpha: 1),
        fillStyle: FillStyle = .gradient,
        gradientEndColor: NSColor? = nil,
        symbolColor: NSColor? = nil,
        glass: Bool = false,
        symbolScale: Double? = nil,
        targetWidth: Int? = nil,
        targetHeight: Int? = nil,
        exportPNG: Bool = false,
        outputDirectory: String = "."
    ) {
        self.fileName = fileName
        self.symbolName = symbolName
        self.backgroundColor = backgroundColor
        self.fillStyle = fillStyle
        self.gradientEndColor = gradientEndColor
        self.symbolColor = symbolColor
        self.glass = glass
        self.symbolScale = symbolScale
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        self.exportPNG = exportPNG
        self.outputDirectory = outputDirectory
    }
}

public enum IconGenerator {
    @discardableResult
    public static func generate(options: GeneratorOptions) throws -> URL {
        let fm = FileManager.default

        // Determine symbol foreground color
        let fgColor = options.symbolColor ?? ColorUtils.autoSymbolColor(forBackground: options.backgroundColor)

        // Render SF Symbol to PNG
        let pngData = try SFSymbolRenderer.render(
            symbolName: options.symbolName,
            targetWidth: options.targetWidth,
            targetHeight: options.targetHeight,
            color: fgColor
        )

        // Build output paths
        let iconDir = URL(fileURLWithPath: options.outputDirectory)
            .appendingPathComponent("\(options.fileName).icon")
        let assetsDir = iconDir.appendingPathComponent("Assets")

        // Create directories
        do {
            try fm.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        } catch {
            throw IconGeneratorError.outputDirectoryCreationFailed(assetsDir.path)
        }

        // Write Container.png
        let pngURL = assetsDir.appendingPathComponent("Container.png")
        do {
            try pngData.write(to: pngURL)
        } catch {
            throw IconGeneratorError.pngWriteFailed(error.localizedDescription)
        }

        // Build icon.json config
        let bgP3 = ColorUtils.toDisplayP3String(options.backgroundColor)
        var gradientEnd: String?
        if options.fillStyle == .linear {
            let endColor = options.gradientEndColor ?? ColorUtils.darken(options.backgroundColor)
            gradientEnd = ColorUtils.toDisplayP3String(endColor)
        }

        let iconConfig = IconConfig(
            fillStyle: options.fillStyle,
            backgroundColor: bgP3,
            gradientEndColor: gradientEnd,
            symbolScale: options.symbolScale,
            glass: options.glass
        )

        // Write icon.json
        let jsonData = try IconJSON.generate(config: iconConfig)
        let jsonURL = iconDir.appendingPathComponent("icon.json")
        do {
            try jsonData.write(to: jsonURL)
        } catch {
            throw IconGeneratorError.jsonWriteFailed(error.localizedDescription)
        }

        // Optionally render composited PNG preview
        if options.exportPNG {
            let previewData = try IconRenderer.render(options: options)
            let previewURL = URL(fileURLWithPath: options.outputDirectory)
                .appendingPathComponent("\(options.fileName).png")
            try previewData.write(to: previewURL)
        }

        return iconDir
    }
}
