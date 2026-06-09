import AppKit
import Darwin
import ICNKit
import SwiftUI

typealias IconFillStyle = ICNKit.FillStyle

@main
struct ICNDemoApp: App {
    init() {
        if CommandLine.arguments.contains("--smoke-test") {
            ICNDemoSmokeTest.run()
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ICNDemoView()
                .frame(minWidth: 760, minHeight: 520)
        }
    }
}

enum ICNDemoSmokeTest {
    static func run() {
        do {
            let outputDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("icn-demo-\(UUID().uuidString)")
            try FileManager.default.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true
            )

            let options = GeneratorOptions(
                fileName: "DemoIcon",
                symbolName: "swift",
                backgroundColor: .systemBlue,
                fillStyle: .gradient,
                glass: true,
                platform: .macOS,
                outputDirectory: outputDirectory.path
            )

            let iconURL = try IconGenerator.generate(options: options)
            let previewData = try IconRenderer.render(
                options: options,
                outputSize: 256,
                outputScale: 2
            )
            guard FileManager.default.fileExists(atPath: iconURL.path),
                  NSImage(data: previewData) != nil
            else {
                fputs("icn-demo smoke test failed: missing generated output\n", stderr)
                exit(1)
            }

            print("icn-demo smoke test generated \(iconURL.path)")
        } catch {
            fputs("icn-demo smoke test failed: \(error)\n", stderr)
            exit(1)
        }
    }
}

struct ICNDemoView: View {
    @State private var symbolName = "swift"
    @State private var fileName = "DemoIcon"
    @State private var selectedColorName = "blue"
    @State private var fillStyle = IconFillStyle.gradient
    @State private var glass = true
    @State private var exportPNG = false
    @State private var symbolScale = 0.57
    @State private var outputDirectory = defaultOutputDirectory
    @State private var previewImage: NSImage?
    @State private var status = "Ready"
    @State private var isGenerating = false

    var body: some View {
        NavigationSplitView {
            IconControls(
                symbolName: $symbolName,
                fileName: $fileName,
                selectedColorName: $selectedColorName,
                fillStyle: $fillStyle,
                glass: $glass,
                exportPNG: $exportPNG,
                symbolScale: $symbolScale,
                outputDirectory: $outputDirectory,
                isGenerating: isGenerating,
                generate: generateIcon,
                chooseOutputDirectory: chooseOutputDirectory
            )
            .navigationSplitViewColumnWidth(min: 320, ideal: 360)
        } detail: {
            IconPreviewPane(
                previewImage: previewImage,
                status: status,
                selectedColorName: selectedColorName,
                fillStyle: fillStyle,
                glass: glass
            )
        }
    }

    private func generateIcon() {
        isGenerating = true
        defer { isGenerating = false }

        do {
            let options = GeneratorOptions(
                fileName: sanitizedFileName,
                symbolName: symbolName.trimmingCharacters(in: .whitespacesAndNewlines),
                backgroundColor: selectedColor,
                fillStyle: fillStyle,
                glass: glass,
                symbolScale: symbolScale,
                exportPNG: exportPNG,
                platform: .macOS,
                outputDirectory: outputDirectory
            )

            let iconURL = try IconGenerator.generate(options: options)
            let previewData = try IconRenderer.render(
                options: options,
                outputSize: 512,
                outputScale: 2
            )
            previewImage = NSImage(data: previewData)
            status = "Generated \(iconURL.lastPathComponent)"
        } catch {
            status = error.localizedDescription
        }
    }

    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.path
        }
    }

    private var selectedColor: NSColor {
        ColorUtils.namedColors
            .first { $0.name == selectedColorName }?
            .nsColor ?? .systemBlue
    }

    private var sanitizedFileName: String {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "DemoIcon" : trimmed
    }
}

struct IconControls: View {
    @Binding var symbolName: String
    @Binding var fileName: String
    @Binding var selectedColorName: String
    @Binding var fillStyle: IconFillStyle
    @Binding var glass: Bool
    @Binding var exportPNG: Bool
    @Binding var symbolScale: Double
    @Binding var outputDirectory: String
    let isGenerating: Bool
    let generate: () -> Void
    let chooseOutputDirectory: () -> Void

    var body: some View {
        Form {
            Section("Icon") {
                TextField("SF Symbol", text: $symbolName)
                TextField("File Name", text: $fileName)

                Picker("Color", selection: $selectedColorName) {
                    ForEach(ColorUtils.namedColors, id: \.name) { namedColor in
                        ColorChoiceRow(namedColor: namedColor)
                            .tag(namedColor.name)
                    }
                }

                Picker("Fill", selection: $fillStyle) {
                    ForEach(IconFillStyle.allCases, id: \.rawValue) { style in
                        Text(displayName(for: style)).tag(style)
                    }
                }
            }

            Section("Rendering") {
                Toggle("Glass", isOn: $glass)
                Toggle("Export PNG", isOn: $exportPNG)

                LabeledContent("Scale") {
                    Slider(value: $symbolScale, in: 0.3...0.8)
                }
            }

            Section("Output") {
                TextField("Directory", text: $outputDirectory)
                Button {
                    chooseOutputDirectory()
                } label: {
                    Label("Choose Directory", systemImage: "folder")
                }
            }

            Section {
                Button {
                    generate()
                } label: {
                    Label("Generate", systemImage: "wand.and.stars")
                }
                .disabled(isGenerating || symbolName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .formStyle(.grouped)
    }

    private func displayName(for style: IconFillStyle) -> String {
        switch style {
        case .solid: return "Solid"
        case .gradient: return "Automatic Gradient"
        case .linear: return "Linear Gradient"
        }
    }
}

struct ColorChoiceRow: View {
    let namedColor: NamedColor

    var body: some View {
        HStack {
            Circle()
                .fill(Color(nsColor: namedColor.nsColor))
                .frame(width: 12, height: 12)
            Text(namedColor.name.capitalized)
        }
    }
}

struct IconPreviewPane: View {
    let previewImage: NSImage?
    let status: String
    let selectedColorName: String
    let fillStyle: IconFillStyle
    let glass: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            IconPreviewImage(previewImage: previewImage)

            Divider()

            IconRenderSummary(
                status: status,
                selectedColorName: selectedColorName,
                fillStyle: fillStyle,
                glass: glass
            )
        }
        .padding(32)
    }
}

struct IconPreviewImage: View {
    let previewImage: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.5))
                .frame(width: 256, height: 256)

            if let previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 256, height: 256)
                    .clipShape(RoundedRectangle(cornerRadius: 56, style: .continuous))
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 72))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct IconRenderSummary: View {
    let status: String
    let selectedColorName: String
    let fillStyle: IconFillStyle
    let glass: Bool

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
            GridRow {
                Text("Status").foregroundStyle(.secondary)
                Text(status)
            }
            GridRow {
                Text("Color").foregroundStyle(.secondary)
                Text(selectedColorName.capitalized)
            }
            GridRow {
                Text("Fill").foregroundStyle(.secondary)
                Text(fillStyle.rawValue.capitalized)
            }
            GridRow {
                Text("Glass").foregroundStyle(.secondary)
                Text(glass ? "Enabled" : "Disabled")
            }
        }
        .textSelection(.enabled)
    }
}

private let defaultOutputDirectory = FileManager.default.urls(
    for: .downloadsDirectory,
    in: .userDomainMask
).first?.path ?? FileManager.default.currentDirectoryPath
