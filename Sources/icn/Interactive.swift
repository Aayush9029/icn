import AppKit
import ICNKit

enum Interactive {
    static func run() throws {
        Term.printHeader()

        // 1. File name
        let fileName = Term.prompt("Icon file name", default: "AppIcon")

        // 2. SF Symbol
        var symbolName = ""
        while true {
            symbolName = Term.prompt("SF Symbol name")
            if symbolName.isEmpty {
                Term.printError("Symbol name is required")
                continue
            }
            if SFSymbolRenderer.isValidSymbol(symbolName) {
                break
            }
            Term.printError("'\(symbolName)' is not a valid SF Symbol")
        }

        // 3. Background color
        Term.printColorPalette()
        var bgColor: NSColor?
        while bgColor == nil {
            let colorInput = Term.prompt("Background color (name or #hex)", default: "blue")
            bgColor = ColorUtils.parseColor(colorInput)
            if bgColor == nil {
                Term.printError("Invalid color. Use a name above or hex (#RRGGBB)")
            }
        }
        let backgroundColor = bgColor!

        // 4. Fill style
        print()
        print("  Fill style:")
        print("    \(Term.bold)1\(Term.reset) Automatic Gradient \(Term.dim)(recommended)\(Term.reset)")
        print("    \(Term.bold)2\(Term.reset) Solid Color")
        print("    \(Term.bold)3\(Term.reset) Linear Gradient")
        let fillChoice = Term.prompt("Choice", default: "1")
        let fillStyle: FillStyle
        var gradientEnd: NSColor?
        switch fillChoice {
        case "2": fillStyle = .solid
        case "3":
            fillStyle = .linear
            print()
            let endInput = Term.prompt("Gradient end color", default: "auto")
            if endInput != "auto" {
                gradientEnd = ColorUtils.parseColor(endInput)
            }
        default: fillStyle = .gradient
        }

        // 5. Glass effect
        print()
        let glassInput = Term.prompt("Glass effect?", default: "n")
        let glass = glassInput.lowercased().hasPrefix("y")

        // 6. Symbol color
        let autoColor = ColorUtils.autoSymbolColorName(forBackground: backgroundColor)
        print()
        let symColorInput = Term.prompt("Symbol color", default: "auto → \(autoColor)")
        let symbolColor: NSColor?
        if symColorInput.hasPrefix("auto") || symColorInput.isEmpty {
            symbolColor = nil // auto
        } else {
            symbolColor = ColorUtils.parseColor(symColorInput)
        }

        // 7. Symbol width
        print()
        let widthInput = Term.prompt("Symbol width (px)", default: "1024")
        let targetWidth = Int(widthInput)

        // 8. Symbol height
        let heightInput = Term.prompt("Symbol height (px)", default: "proportional")
        let targetHeight = heightInput == "proportional" ? nil : Int(heightInput)

        // 9. Export PNG
        print()
        let pngInput = Term.prompt("Export composited PNG preview?", default: "n")
        let exportPNG = pngInput.lowercased().hasPrefix("y")

        // Generate
        print()
        let outputDir = FileManager.default.currentDirectoryPath
        let options = GeneratorOptions(
            fileName: fileName,
            symbolName: symbolName,
            backgroundColor: backgroundColor,
            fillStyle: fillStyle,
            gradientEndColor: gradientEnd,
            symbolColor: symbolColor,
            glass: glass,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            exportPNG: exportPNG,
            outputDirectory: outputDir
        )

        let outputURL = try IconGenerator.generate(options: options)
        print()
        Term.printSuccess("Generated \(outputURL.lastPathComponent)")
        print("    \(Term.dim)\(outputURL.path)\(Term.reset)")
        if exportPNG {
            let pngPath = URL(fileURLWithPath: outputDir)
                .appendingPathComponent("\(fileName).png").path
            Term.printSuccess("Exported \(fileName).png")
            print("    \(Term.dim)\(pngPath)\(Term.reset)")
        }
        print()
    }
}
