import Foundation

public enum ICToolError: Error, CustomStringConvertible {
    case notFound
    case failed(String)

    public var description: String {
        switch self {
        case .notFound:
            return "ictool not found. Install Xcode 16+ with Icon Composer."
        case .failed(let msg):
            return "ictool failed: \(msg)"
        }
    }
}

public enum Platform: String, CaseIterable, Sendable {
    case iOS
    case macOS
    case watchOS
}

public enum Rendition: String, CaseIterable, Sendable {
    case `default` = "Default"
    case dark = "Dark"
    case tintedDark = "TintedDark"
}

public enum ICTool {
    private static let searchPaths = [
        "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool",
        "/Applications/Xcode-beta.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool",
    ]

    public static var path: String? {
        searchPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    public static var isAvailable: Bool { path != nil }

    /// Renders a .icon bundle to PNG using Apple's ictool (pixel-perfect).
    public static func exportImage(
        iconPath: String,
        outputPath: String,
        platform: Platform = .iOS,
        rendition: Rendition = .default,
        width: Int = 1024,
        height: Int = 1024,
        scale: Int = 1
    ) throws {
        guard let toolPath = path else {
            throw ICToolError.notFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: toolPath)
        process.arguments = [
            iconPath,
            "--export-image",
            "--output-file", outputPath,
            "--platform", platform.rawValue,
            "--rendition", rendition.rawValue,
            "--width", String(width),
            "--height", String(height),
            "--scale", String(scale),
        ]

        let stderr = Pipe()
        process.standardError = stderr
        process.standardOutput = Pipe() // ictool outputs JSON to stdout

        try process.run()
        process.waitUntilExit()

        // ictool returns 0 even with empty JSON output on success
        // Check if the output file was actually created
        if !FileManager.default.fileExists(atPath: outputPath) {
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw ICToolError.failed(errorMsg)
        }
    }
}
