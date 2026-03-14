import AppKit
import CoreGraphics
import SwiftUI

public enum IconRendererError: Error, CustomStringConvertible {
    case symbolRenderFailed
    case contextCreationFailed
    case imageCreationFailed
    case pngExportFailed

    public var description: String {
        switch self {
        case .symbolRenderFailed: return "Failed to render SF Symbol for preview."
        case .contextCreationFailed: return "Failed to create graphics context."
        case .imageCreationFailed: return "Failed to create final image."
        case .pngExportFailed: return "Failed to export PNG."
        }
    }
}

public enum IconRenderer {
    /// Renders a composited icon preview as a PNG.
    /// Draws the squircle background + fill + symbol + effects.
    public static func render(
        options: GeneratorOptions,
        outputSize: Int = 1024,
        outputScale: Int = 3
    ) throws -> Data {
        let symbolColor = options.symbolColor
            ?? ColorUtils.autoSymbolColor(forBackground: options.backgroundColor)

        let symbolPNG = try SFSymbolRenderer.render(
            symbolName: options.symbolName,
            targetWidth: options.targetWidth,
            targetHeight: options.targetHeight,
            color: symbolColor
        )

        guard let symbolNSImage = NSImage(data: symbolPNG),
              let symbolCGImage = symbolNSImage.cgImage(
                  forProposedRect: nil, context: nil, hints: nil
              )
        else {
            throw IconRendererError.symbolRenderFailed
        }

        let pt = CGFloat(outputSize)
        let px = outputSize * outputScale

        guard let colorSpace = CGColorSpace(name: CGColorSpace.displayP3),
              let ctx = CGContext(
                  data: nil,
                  width: px,
                  height: px,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else {
            throw IconRendererError.contextCreationFailed
        }

        ctx.scaleBy(x: CGFloat(outputScale), y: CGFloat(outputScale))

        let iconRect = CGRect(x: 0, y: 0, width: pt, height: pt)

        // Clip to continuous-corner squircle (Apple's icon shape)
        let cornerRadius = pt * 0.2207
        let squircle = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .path(in: iconRect)
            .cgPath
        ctx.addPath(squircle)
        ctx.clip()

        // Background fill
        drawFill(ctx: ctx, rect: iconRect, options: options)

        // Symbol rect
        let scale = options.symbolScale ?? (options.glass ? 0.63 : 0.57)
        let symbolRect = symbolRect(
            symbolSize: symbolNSImage.size,
            iconSize: pt,
            scale: scale
        )

        // Shadow behind symbol
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 0, height: -pt * 0.008),
            blur: pt * 0.025,
            color: CGColor(gray: 0, alpha: 0.35)
        )
        ctx.setAlpha(1.0)
        ctx.draw(symbolCGImage, in: symbolRect)
        ctx.restoreGState()

        // Draw symbol again (without shadow) with translucency
        ctx.saveGState()
        ctx.setAlpha(0.85)
        ctx.draw(symbolCGImage, in: symbolRect)
        ctx.restoreGState()

        // Glass highlight
        if options.glass {
            drawGlassHighlight(ctx: ctx, symbolRect: symbolRect)
        }

        guard let cgImage = ctx.makeImage() else {
            throw IconRendererError.imageCreationFailed
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw IconRendererError.pngExportFailed
        }

        return pngData
    }

    // MARK: - Private

    private static func drawFill(
        ctx: CGContext, rect: CGRect, options: GeneratorOptions
    ) {
        let bg = options.backgroundColor
        guard let p3 = bg.usingColorSpace(.displayP3) else {
            ctx.setFillColor(bg.cgColor)
            ctx.fill([rect])
            return
        }

        switch options.fillStyle {
        case .solid:
            ctx.setFillColor(p3.cgColor)
            ctx.fill([rect])

        case .gradient:
            let lighter = ColorUtils.lighten(bg, by: 0.08)
            let darker = ColorUtils.darken(bg, by: 0.12)
            drawLinearGradient(
                ctx: ctx, rect: rect,
                topColor: lighter, bottomColor: darker
            )

        case .linear:
            let endColor = options.gradientEndColor ?? ColorUtils.darken(bg, by: 0.15)
            drawLinearGradient(
                ctx: ctx, rect: rect,
                topColor: bg, bottomColor: endColor
            )
        }
    }

    private static func drawLinearGradient(
        ctx: CGContext, rect: CGRect,
        topColor: NSColor, bottomColor: NSColor
    ) {
        let cs = CGColorSpace(name: CGColorSpace.displayP3)
            ?? CGColorSpaceCreateDeviceRGB()
        let top = topColor.usingColorSpace(.displayP3) ?? topColor
        let bot = bottomColor.usingColorSpace(.displayP3) ?? bottomColor

        guard let gradient = CGGradient(
            colorsSpace: cs,
            colors: [top.cgColor, bot.cgColor] as CFArray,
            locations: [0.0, 1.0]
        ) else { return }

        // CGContext: y=maxY is top, y=0 is bottom
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.maxY),
            end: CGPoint(x: rect.midX, y: rect.minY),
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    private static func symbolRect(
        symbolSize: NSSize, iconSize: CGFloat, scale: Double
    ) -> CGRect {
        let maxDim = iconSize * CGFloat(scale)
        let aspect = symbolSize.width / symbolSize.height

        let w: CGFloat
        let h: CGFloat
        if aspect >= 1 {
            w = maxDim
            h = maxDim / aspect
        } else {
            h = maxDim
            w = maxDim * aspect
        }

        return CGRect(
            x: (iconSize - w) / 2,
            y: (iconSize - h) / 2,
            width: w,
            height: h
        )
    }

    private static func drawGlassHighlight(
        ctx: CGContext, symbolRect: CGRect
    ) {
        ctx.saveGState()
        ctx.clip(to: symbolRect)

        // Specular highlight — radial gradient at the top of the symbol
        let center = CGPoint(
            x: symbolRect.midX,
            y: symbolRect.midY + symbolRect.height * 0.25
        )
        let radius = symbolRect.width * 0.45

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                CGColor(gray: 1, alpha: 0.12),
                CGColor(gray: 1, alpha: 0),
            ] as CFArray,
            locations: [0.0, 1.0]
        ) else {
            ctx.restoreGState()
            return
        }

        ctx.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: 0,
            endCenter: center, endRadius: radius,
            options: []
        )

        ctx.restoreGState()
    }
}
