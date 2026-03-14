import AppKit

public enum SFSymbolError: Error, CustomStringConvertible {
    case symbolNotFound(String)
    case renderingFailed
    case pngConversionFailed

    public var description: String {
        switch self {
        case .symbolNotFound(let name):
            return "SF Symbol '\(name)' not found. Check the name and try again."
        case .renderingFailed:
            return "Failed to render the SF Symbol."
        case .pngConversionFailed:
            return "Failed to convert rendered image to PNG."
        }
    }
}

public enum SFSymbolRenderer {
    public static func render(
        symbolName: String,
        targetWidth: Int? = nil,
        targetHeight: Int? = nil,
        weight: NSFont.Weight = .medium,
        color: NSColor = .white
    ) throws -> Data {
        guard let baseImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
            throw SFSymbolError.symbolNotFound(symbolName)
        }

        // Render at reference point size to measure natural aspect ratio
        let refPointSize: CGFloat = 100
        let refConfig = NSImage.SymbolConfiguration(pointSize: refPointSize, weight: weight)
        guard let refImage = baseImage.withSymbolConfiguration(refConfig) else {
            throw SFSymbolError.renderingFailed
        }

        let refPixelW = refImage.size.width * 3.0
        let refPixelH = refImage.size.height * 3.0

        // Calculate target dimensions
        let defaultWidth: CGFloat = 1024
        let targetW: CGFloat
        let targetH: CGFloat

        if let w = targetWidth, let h = targetHeight {
            // Fit within bounds, maintaining aspect ratio
            let scaleW = CGFloat(w) / refPixelW
            let scaleH = CGFloat(h) / refPixelH
            let scale = min(scaleW, scaleH)
            targetW = refPixelW * scale
            targetH = refPixelH * scale
        } else if let w = targetWidth {
            targetW = CGFloat(w)
            targetH = targetW * (refPixelH / refPixelW)
        } else {
            targetW = defaultWidth
            targetH = defaultWidth * (refPixelH / refPixelW)
        }

        // Calculate point size to achieve target pixel width at 3x
        let pointSize = refPointSize * (targetW / refPixelW)

        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
            .applying(NSImage.SymbolConfiguration(paletteColors: [color]))

        guard let finalImage = baseImage.withSymbolConfiguration(config) else {
            throw SFSymbolError.renderingFailed
        }

        let pixelW = Int(ceil(finalImage.size.width * 3))
        let pixelH = Int(ceil(finalImage.size.height * 3))

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelW,
            pixelsHigh: pixelH,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw SFSymbolError.renderingFailed
        }

        bitmap.size = finalImage.size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

        finalImage.draw(
            in: NSRect(origin: .zero, size: finalImage.size),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )

        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw SFSymbolError.pngConversionFailed
        }

        return pngData
    }

    public static func isValidSymbol(_ name: String) -> Bool {
        NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
    }
}
