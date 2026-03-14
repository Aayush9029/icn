import Foundation

public enum FillStyle: String, CaseIterable, Sendable {
    case solid
    case gradient
    case linear
}

public struct GradientOrientation: Sendable {
    public var startX: Double
    public var startY: Double
    public var stopX: Double
    public var stopY: Double

    public init(startX: Double = 0.5, startY: Double = 0, stopX: Double = 0.5, stopY: Double = 0.7) {
        self.startX = startX
        self.startY = startY
        self.stopX = stopX
        self.stopY = stopY
    }

    public static let topToBottom = GradientOrientation()
}

public struct IconConfig: Sendable {
    public var fillStyle: FillStyle
    public var backgroundColor: String
    public var gradientEndColor: String?
    public var gradientOrientation: GradientOrientation?
    public var symbolImageName: String
    public var symbolScale: Double
    public var glass: Bool
    public var shadowOpacity: Double
    public var translucencyEnabled: Bool
    public var translucencyValue: Double

    public init(
        fillStyle: FillStyle = .gradient,
        backgroundColor: String,
        gradientEndColor: String? = nil,
        gradientOrientation: GradientOrientation? = nil,
        symbolImageName: String = "Container.png",
        symbolScale: Double? = nil,
        glass: Bool = false,
        shadowOpacity: Double = 0.5,
        translucencyEnabled: Bool = true,
        translucencyValue: Double = 0.5
    ) {
        self.fillStyle = fillStyle
        self.backgroundColor = backgroundColor
        self.gradientEndColor = gradientEndColor
        self.gradientOrientation = gradientOrientation
        self.symbolImageName = symbolImageName
        self.symbolScale = symbolScale ?? (glass ? 0.63 : 0.57)
        self.glass = glass
        self.shadowOpacity = shadowOpacity
        self.translucencyEnabled = translucencyEnabled
        self.translucencyValue = translucencyValue
    }
}

public enum IconJSON {
    public static func generate(config: IconConfig) throws -> Data {
        var root: [String: Any] = [:]

        switch config.fillStyle {
        case .solid:
            root["fill"] = ["solid": config.backgroundColor]
        case .gradient:
            root["fill"] = ["automatic-gradient": config.backgroundColor]
        case .linear:
            let endColor = config.gradientEndColor ?? config.backgroundColor
            let orientation = config.gradientOrientation ?? .topToBottom
            root["fill"] = [
                "linear-gradient": [config.backgroundColor, endColor],
                "orientation": [
                    "start": ["x": orientation.startX, "y": orientation.startY],
                    "stop": ["x": orientation.stopX, "y": orientation.stopY],
                ] as [String: Any],
            ] as [String: Any]
        }

        var layer: [String: Any] = [
            "image-name": config.symbolImageName,
            "name": config.glass ? "Container" : "symbol-image",
            "position": [
                "scale": NSDecimalNumber(string: String(format: "%.2f", config.symbolScale)),
                "translation-in-points": [0, 0],
            ] as [String: Any],
        ]

        if config.glass {
            layer["glass"] = true
        }

        var group: [String: Any] = [
            "layers": [layer],
            "shadow": [
                "kind": "neutral",
                "opacity": NSDecimalNumber(string: String(format: "%.1f", config.shadowOpacity)),
            ] as [String: Any],
            "translucency": [
                "enabled": config.translucencyEnabled,
                "value": NSDecimalNumber(string: String(format: "%.1f", config.translucencyValue)),
            ] as [String: Any],
        ]

        if !config.glass {
            group["name"] = "Symbol"
        }

        root["groups"] = [group]

        root["supported-platforms"] = [
            "circles": ["watchOS"],
            "squares": "shared",
        ] as [String: Any]

        return try JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        )
    }
}
