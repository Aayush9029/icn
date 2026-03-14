## All these icons were generated using icn and claude.

<img src="https://github.com/Aayush9029/icn/blob/main/assets/example.png"/>MIT


> [!NOTE]  
> I've reverse engineered the Icon Composer app, this cli allows you (agents) to create app icons using terminal and also export them as PNG.

# icn

Generate `.icon` files from SF Symbols — the new Apple Icon Composer format (Xcode 16+).

## Installation

```bash
brew install aayush9029/tap/icn
```

Or tap first:

```bash
brew tap aayush9029/tap
brew install icn
```

## Usage

```bash
# Interactive mode — guided prompts
icn

# Direct mode — SF Symbol with auto gradient background
icn swift --color blue

# Solid red background with glass effect
icn heart.fill --color "#FF3B30" --fill solid --glass

# Custom name, linear gradient, specific width
icn star.fill --name MyAppIcon --color orange --fill linear --width 2048

# Override auto symbol color
icn swift --color white --symbol-color black

# Export pixel-perfect PNG (uses ictool from Icon Composer)
icn swift --color blue --glass --png

# Dark mode rendition
icn swift --color blue --glass --png --rendition dark

# macOS platform export
icn swift --color blue --png --platform macos
```

## Options

| Flag | Description |
|---|---|
| `<symbol>` | SF Symbol name (e.g. `swift`, `heart.fill`) |
| `-n, --name` | Output file name (default: `AppIcon`) |
| `-c, --color` | Background color — hex (`#FF0000`) or name (`red`, `blue`...) |
| `-f, --fill` | Fill style: `solid`, `gradient`, `linear` (default: `gradient`) |
| `--symbol-color` | Symbol foreground color (default: auto black/white) |
| `-g, --glass` | Enable glass effect |
| `-s, --scale` | Symbol scale within icon (default: 0.57, glass: 0.63) |
| `-w, --width` | Symbol render width in pixels (default: 1024) |
| `--height` | Symbol render height (default: proportional) |
| `--png` | Export composited PNG (pixel-perfect via ictool, or built-in fallback) |
| `--platform` | Target platform: `ios`, `macos`, `watchos` (default: `ios`) |
| `--rendition` | Rendition: `default`, `dark`, `tinted-dark` (default: `default`) |
| `-o, --output` | Output directory (default: current) |

## How it works

1. Renders the SF Symbol as a white (or auto-detected color) PNG on transparent background
2. Generates an `icon.json` with fill style, scale, shadow, and translucency settings
3. Bundles them into a `.icon` directory — ready for Xcode or Icon Composer
4. Auto-detects optimal symbol color (black/white) based on background luminance
5. `--png` uses Apple's `ictool` (bundled with Icon Composer) for pixel-perfect rendering with full glass, lighting, and shadow effects — falls back to a built-in CoreGraphics renderer if Xcode isn't installed

## Requirements

- macOS 14+
- Xcode 16+ (for Icon Composer support)
