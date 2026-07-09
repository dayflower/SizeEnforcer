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

The Makefile is the canonical entry point:

```sh
make build     # debug build
make run       # build and launch
make release   # release build
make test      # run the SizeEnforcerKitTests suite
make check     # lint with swift-format (no changes)
make fix       # reformat sources in place with swift-format
make app       # assemble ./build/SizeEnforcer.app (ad-hoc signed)
```

- Toolchain: Swift 6, targeting macOS 15 (Sequoia) or later.
- The menu-bar icon lives in an asset catalog
  (`Sources/SizeEnforcerKit/Resources/Assets.xcassets`). The default `native`
  build system copies asset catalogs verbatim, so `make app` builds with the
  Swift Build engine (`swift build --build-system swiftbuild`) instead: it
  compiles the catalog into a loadable `Assets.car` and emits a properly
  structured resource bundle whose `Bundle.module` accessor finds
  `Contents/Resources` (`--arch arm64` keeps it a single-architecture build).
  This still needs a full **Xcode** for actool;
  select it with `sudo xcode-select -s /Applications/Xcode.app` (or set
  `DEVELOPER_DIR`). When running via `make run`/`swift run` (the `native` build
  system), the catalog is uncompiled and the tray icon silently falls back to an
  SF Symbol.
- The app icon is an Icon Composer document (`design/AppIcon.icon`). `make app`
  compiles it with `actool` into the bundle's top-level
  `Contents/Resources/Assets.car` (plus a fallback `AppIcon.icns`) and points the
  Info.plist `CFBundleIconName`/`CFBundleIconFile` keys at it. This likewise
  needs a full **Xcode**, and only takes effect in the assembled `.app`, not
  `make run`.
- Tests use **Swift Testing**. With **Command Line Tools only** (no Xcode),
  plain `swift test` cannot locate the Swift Testing runtime; `make test`
  detects this and adds the required framework/rpath flags automatically.
- Also verify UI/OS-integration changes by building and running the app.
- `scripts/make-app.sh <dir>` assembles the `.app` into a custom directory.

## Layout

- `Sources/SizeEnforcer/` — executable target; `main.swift` only, which calls
  `sizeEnforcerMain()` from the Kit.
- `Sources/SizeEnforcerKit/` — library target holding all app logic (so tests
  can `@testable import` it). `sizeEnforcerMain()` is the only `public` symbol;
  the rest stays `internal`. Value types live in `Models/`, the SwiftUI
  settings window in `Settings/`.
- `Tests/SizeEnforcerKitTests/` — Swift Testing suite for `SizeEnforcerKit`.
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
- Run `make check` (swift-format lint) before committing.
