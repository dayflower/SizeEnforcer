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

- Toolchain: Swift 6, targeting macOS 14 (Sonoma) or later.
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
