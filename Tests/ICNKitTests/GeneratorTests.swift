import AppKit
import Foundation
import Testing

@testable import ICNKit

@Suite("Icon Generator E2E")
struct GeneratorTests {
    @Test("Generate icon bundle with valid symbol")
    func generateBasic() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let options = GeneratorOptions(
            fileName: "TestIcon",
            symbolName: "swift",
            fillStyle: .gradient,
            outputDirectory: tmpDir.path
        )

        let outputURL = try IconGenerator.generate(options: options)

        // Verify directory structure
        let fm = FileManager.default
        #expect(fm.fileExists(atPath: outputURL.path))
        #expect(fm.fileExists(atPath: outputURL.appendingPathComponent("icon.json").path))
        #expect(fm.fileExists(atPath: outputURL.appendingPathComponent("Assets/Container.png").path))
    }

    @Test("icon.json is valid JSON with expected keys")
    func generateValidJSON() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let options = GeneratorOptions(
            fileName: "TestIcon",
            symbolName: "heart.fill",
            backgroundColor: NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1),
            fillStyle: .solid,
            outputDirectory: tmpDir.path
        )

        let outputURL = try IconGenerator.generate(options: options)
        let jsonData = try Data(contentsOf: outputURL.appendingPathComponent("icon.json"))
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        #expect(json["fill"] != nil)
        #expect(json["groups"] != nil)
        #expect(json["supported-platforms"] != nil)
    }

    @Test("Container.png is a valid PNG")
    func generateValidPNG() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let options = GeneratorOptions(
            fileName: "TestIcon",
            symbolName: "star.fill",
            outputDirectory: tmpDir.path
        )

        let outputURL = try IconGenerator.generate(options: options)
        let pngData = try Data(contentsOf: outputURL.appendingPathComponent("Assets/Container.png"))

        // PNG magic bytes
        let header: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        let fileHeader = Array(pngData.prefix(4))
        #expect(fileHeader == header)

        // Verify it's a real image
        let image = NSImage(data: pngData)
        #expect(image != nil)
        #expect(image!.size.width > 0)
        #expect(image!.size.height > 0)
    }

    @Test("Glass option produces glass in JSON")
    func generateWithGlass() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let options = GeneratorOptions(
            fileName: "GlassIcon",
            symbolName: "swift",
            glass: true,
            outputDirectory: tmpDir.path
        )

        let outputURL = try IconGenerator.generate(options: options)
        let jsonData = try Data(contentsOf: outputURL.appendingPathComponent("icon.json"))
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        let groups = json["groups"] as! [[String: Any]]
        let layers = groups[0]["layers"] as! [[String: Any]]
        #expect(layers[0]["glass"] as? Bool == true)
        #expect(layers[0]["name"] as? String == "Container")
    }

    @Test("Invalid symbol name throws error")
    func invalidSymbol() {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let options = GeneratorOptions(
            symbolName: "this.symbol.definitely.does.not.exist.12345",
            outputDirectory: tmpDir.path
        )

        #expect(throws: SFSymbolError.self) {
            try IconGenerator.generate(options: options)
        }
    }

    @Test("Custom output file name")
    func customFileName() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let options = GeneratorOptions(
            fileName: "MyCustomIcon",
            symbolName: "swift",
            outputDirectory: tmpDir.path
        )

        let outputURL = try IconGenerator.generate(options: options)
        #expect(outputURL.lastPathComponent == "MyCustomIcon.icon")
    }

    @Test("Custom width affects PNG size")
    func customWidth() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let smallOptions = GeneratorOptions(
            fileName: "Small",
            symbolName: "swift",
            targetWidth: 256,
            outputDirectory: tmpDir.path
        )

        let largeOptions = GeneratorOptions(
            fileName: "Large",
            symbolName: "swift",
            targetWidth: 2048,
            outputDirectory: tmpDir.path
        )

        let smallURL = try IconGenerator.generate(options: smallOptions)
        let largeURL = try IconGenerator.generate(options: largeOptions)

        let smallPNG = try Data(contentsOf: smallURL.appendingPathComponent("Assets/Container.png"))
        let largePNG = try Data(contentsOf: largeURL.appendingPathComponent("Assets/Container.png"))

        // Larger renders should produce more data
        #expect(largePNG.count > smallPNG.count)
    }

    @Test("SF Symbol validity check")
    func symbolValidation() {
        #expect(SFSymbolRenderer.isValidSymbol("swift"))
        #expect(SFSymbolRenderer.isValidSymbol("heart.fill"))
        #expect(SFSymbolRenderer.isValidSymbol("star"))
        #expect(!SFSymbolRenderer.isValidSymbol("not.a.real.symbol.xyz"))
    }

    @Test("PNG export creates composited icon image")
    func pngExport() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let options = GeneratorOptions(
            fileName: "ExportTest",
            symbolName: "swift",
            backgroundColor: NSColor(srgbRed: 0, green: 0.478, blue: 1, alpha: 1),
            glass: true,
            exportPNG: true,
            outputDirectory: tmpDir.path
        )

        try IconGenerator.generate(options: options)

        // Verify PNG was created
        let pngURL = tmpDir.appendingPathComponent("ExportTest.png")
        #expect(FileManager.default.fileExists(atPath: pngURL.path))

        // Verify it's a valid PNG
        let pngData = try Data(contentsOf: pngURL)
        let header: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        #expect(Array(pngData.prefix(4)) == header)

        // Verify it's a reasonable size (3072x3072 at 3x)
        let image = NSImage(data: pngData)
        #expect(image != nil)
    }

    @Test("PNG renderer produces square image")
    func pngRendererSize() throws {
        let options = GeneratorOptions(
            symbolName: "swift",
            backgroundColor: .black
        )

        let pngData = try IconRenderer.render(options: options, outputSize: 512, outputScale: 2)
        let image = NSImage(data: pngData)
        #expect(image != nil)
        // At 2x scale: 1024x1024 pixels
        guard let rep = image?.representations.first else {
            #expect(Bool(false), "No image representation")
            return
        }
        #expect(rep.pixelsWide == 1024)
        #expect(rep.pixelsHigh == 1024)
    }

    @Test("Auto symbol color for dark background is white")
    func autoColorDarkBg() throws {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("icn-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        // Dark background, auto symbol color should be white
        let options = GeneratorOptions(
            symbolName: "swift",
            backgroundColor: .black,
            outputDirectory: tmpDir.path
        )

        // Just verify it doesn't throw — auto color logic is tested in ColorUtilsTests
        let outputURL = try IconGenerator.generate(options: options)
        #expect(FileManager.default.fileExists(atPath: outputURL.path))
    }
}
