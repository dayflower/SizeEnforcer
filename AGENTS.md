# AGENTS.md

## Project overview

SizeEnforcer is a lightweight macOS menu-bar app that resizes windows of other
applications to preset sizes. The user picks a window with the cursor (like the
macOS screenshot picker) and snaps it to a registered `width × height`. Presets
are stored per application, keyed by bundle identifier.

- Runs as an accessory app (`LSUIElement`) — no Dock icon, no main window.
- Resizes other apps' windows through the Accessibility API, so the app must be
  granted **Accessibility** permission to function.

## Build, run, and package

```sh
swift build            # debug build
swift run              # build and launch
swift build -c release # release build

scripts/make-app.sh          # assemble ./build/SizeEnforcer.app (ad-hoc signed)
scripts/make-app.sh <dir>    # choose an output directory
```

- Toolchain: Swift 6, targeting macOS 14 (Sonoma) or later.
- There is no test target yet; verify changes by building and running the app.
- VS Code launch configs live in `.vscode/launch.json` (Debug / Release).

## Layout

- `Sources/SizeEnforcer/` — all app source.
  - `main.swift` — entry point; sets `.accessory` activation policy.
  - `AppDelegate.swift` — menu-bar controller; owns the status item, stores, and
    the window picker.
  - `WindowPicker.swift`, `PickerOverlay*.swift` — interactive cursor-based
    window selection and its overlay/highlight.
  - `WindowEnumerator.swift`, `WindowInfo.swift` — enumerate on-screen windows.
  - `WindowResizer.swift` — performs the resize via the Accessibility API;
    also owns Accessibility permission checks/prompts.
  - `AppIdentity.swift` — resolves the per-app grouping key (bundle ID, with a
    fallback to the window owner name).
  - `PresetStore.swift`, `ShortcutStore.swift`, `GeneralSettingsStore.swift` —
    persistence (`ObservableObject`, JSON in Application Support / UserDefaults).
  - `HotKeyCenter.swift` — global hotkey registration.
  - `SelectionMenu.swift` — the popup that offers registered sizes after a pick.
  - `RegionMath.swift`, `ScreenGeometry.swift` — geometry helpers.
  - `Models/` — value types (`SizePreset`, `HotKeyShortcut`).
  - `Settings/` — SwiftUI settings window and components.
- `scripts/make-app.sh` — builds a release binary and wraps it in a `.app`.
- `notes/` — design notes (Japanese).

## Architecture notes

- UI mixes AppKit (menu bar, picker overlay, selection popup) and SwiftUI
  (settings window). Stores are `@MainActor ObservableObject` so both sides can
  observe them.
- Main-thread work is annotated `@MainActor`; keep new UI/AppKit code consistent
  with that and with Swift 6 strict concurrency (avoid non-Sendable globals — see
  the `AXTrustedCheckOptionPrompt` string-literal workaround in
  `WindowResizer.swift`).
- Presets are grouped by bundle identifier so they survive app renames/updates.

## Conventions

- Code, comments, documentation, commit messages, and PR/Issue descriptions are
  written in **English**.
- Commit messages follow Conventional Commits, without a `(scope)`; keep the
  title to a single line.
