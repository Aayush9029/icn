# icn

`icn` is a macOS command-line tool that makes Icon Composer `.icon` packages and PNG renditions from SF Symbols. Swift Package, Swift Argument Parser, macOS 14 or later. Users install it with `brew install aayush9029/tap/icn`. Status: active, public, MIT.

## Commands

| Task | Command |
|------|---------|
| Build | `swift build` |
| Run the CLI | `swift run icn swift --color blue` (no arguments starts interactive mode) |
| Test | `swift test` |
| SwiftUI demo | `swift run icn-demo`, or `swift run icn-demo --smoke-test` |

## Architecture

| Target | Role |
|--------|------|
| `ICNKit` | Library: renders the SF Symbol, writes `icon.json` and the `.icon` package, and calls `ictool` for PNG output |
| `icn` | CLI: `ArgumentParser` flags plus the interactive terminal mode |
| `ICNDemo` | Small SwiftUI app around `ICNKit` |

## Rules

- PNG export uses Apple's `ictool` from Icon Composer in Xcode (`ICTool.swift` checks `Xcode.app` and `Xcode-beta.app`). Keep PNG output on `ictool`, because it renders the glass effect the same as Xcode.
- Put generation logic in `ICNKit`, not in the CLI or the demo, so both use the same code.
- If you add or change a flag, update the Options table in `README.md`.
- The Homebrew formula lives in `Aayush9029/homebrew-tap`. Use the `oss-cli-release` skill for a release.
