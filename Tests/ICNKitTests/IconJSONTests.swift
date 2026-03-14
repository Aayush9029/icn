import Foundation
import Testing

@testable import ICNKit

@Suite("Icon JSON Generation")
struct IconJSONTests {
    @Test("Solid fill generates correct structure")
    func solidFill() throws {
        let config = IconConfig(
            fillStyle: .solid,
            backgroundColor: "display-p3:1.00000,0.00000,0.00000,1.00000"
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let fill = json["fill"] as! [String: Any]
        #expect(fill["solid"] as? String == "display-p3:1.00000,0.00000,0.00000,1.00000")
    }

    @Test("Automatic gradient fill")
    func automaticGradient() throws {
        let config = IconConfig(
            fillStyle: .gradient,
            backgroundColor: "display-p3:0.00000,0.47800,1.00000,1.00000"
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let fill = json["fill"] as! [String: Any]
        #expect(fill["automatic-gradient"] != nil)
    }

    @Test("Linear gradient fill with two colors and orientation")
    func linearGradient() throws {
        let config = IconConfig(
            fillStyle: .linear,
            backgroundColor: "display-p3:0.00000,0.00000,0.00000,1.00000",
            gradientEndColor: "display-p3:0.10000,0.10000,0.10000,1.00000"
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let fill = json["fill"] as! [String: Any]
        let colors = fill["linear-gradient"] as! [String]
        #expect(colors.count == 2)
        #expect(fill["orientation"] != nil)
    }

    @Test("Default scale is 0.38 without glass")
    func defaultScaleNoGlass() throws {
        let config = IconConfig(
            fillStyle: .solid,
            backgroundColor: "display-p3:0,0,0,1"
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let groups = json["groups"] as! [[String: Any]]
        let layers = groups[0]["layers"] as! [[String: Any]]
        let position = layers[0]["position"] as! [String: Any]
        let scale = position["scale"] as! Double
        #expect(abs(scale - 0.38) < 0.001)
    }

    @Test("Glass sets scale to 0.42 and adds glass flag")
    func glassEffect() throws {
        let config = IconConfig(
            fillStyle: .gradient,
            backgroundColor: "display-p3:0,0,0,1",
            glass: true
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let groups = json["groups"] as! [[String: Any]]
        let layers = groups[0]["layers"] as! [[String: Any]]
        let layer = layers[0]

        #expect(layer["glass"] as? Bool == true)
        #expect(layer["name"] as? String == "Container")

        let position = layer["position"] as! [String: Any]
        let scale = position["scale"] as! Double
        #expect(abs(scale - 0.42) < 0.001)
    }

    @Test("Non-glass has group name 'Symbol'")
    func nonGlassGroupName() throws {
        let config = IconConfig(
            fillStyle: .solid,
            backgroundColor: "display-p3:0,0,0,1"
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let groups = json["groups"] as! [[String: Any]]
        #expect(groups[0]["name"] as? String == "Symbol")
    }

    @Test("Glass has no group name")
    func glassNoGroupName() throws {
        let config = IconConfig(
            fillStyle: .solid,
            backgroundColor: "display-p3:0,0,0,1",
            glass: true
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let groups = json["groups"] as! [[String: Any]]
        #expect(groups[0]["name"] == nil)
    }

    @Test("Supported platforms structure")
    func supportedPlatforms() throws {
        let config = IconConfig(
            fillStyle: .solid,
            backgroundColor: "display-p3:0,0,0,1"
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let platforms = json["supported-platforms"] as! [String: Any]
        let circles = platforms["circles"] as! [String]
        #expect(circles == ["watchOS"])
        #expect(platforms["squares"] as? String == "shared")
    }

    @Test("Shadow and translucency defaults")
    func shadowTranslucency() throws {
        let config = IconConfig(
            fillStyle: .solid,
            backgroundColor: "display-p3:0,0,0,1"
        )
        let data = try IconJSON.generate(config: config)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let groups = json["groups"] as! [[String: Any]]
        let shadow = groups[0]["shadow"] as! [String: Any]
        #expect(shadow["kind"] as? String == "neutral")
        #expect(shadow["opacity"] as? Double == 0.5)

        let translucency = groups[0]["translucency"] as! [String: Any]
        #expect(translucency["enabled"] as? Bool == true)
        #expect(translucency["value"] as? Double == 0.5)
    }

    @Test("Output is valid JSON")
    func validJSON() throws {
        let config = IconConfig(
            fillStyle: .gradient,
            backgroundColor: "display-p3:0,0.478,1,1",
            glass: true
        )
        let data = try IconJSON.generate(config: config)
        let str = String(data: data, encoding: .utf8)!
        #expect(str.contains("automatic-gradient"))
        #expect(str.contains("glass"))
    }
}
