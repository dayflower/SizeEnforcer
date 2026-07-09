# SizeEnforcer

SizeEnforcer is a lightweight macOS menu-bar app that resizes windows of other
applications to sizes you register in advance. Pick a window with your cursor —
the same way you select a window for a screenshot — and snap it to a preset
size. Sizes are remembered per application, so each app gets its own list of
target dimensions.

## Features

- **Menu-bar resident** — runs as an accessory app with no Dock icon or main
  window.
- **Cursor-based window picker** — highlights the window under your pointer and
  resizes the one you click.
- **Per-app presets** — register any number of `width × height` sizes, grouped
  by the app's bundle identifier so they persist across renames and updates.
- **Global hotkey** — start the picker with a configurable keyboard shortcut
  (⌘⌥⌃⇧ + key).

## Requirements

- macOS 15 (Sequoia) or later
- Swift 6 toolchain (for building from source)
- **Accessibility permission** — SizeEnforcer resizes other apps' windows via
  the Accessibility API, so it must be granted access under
  System Settings → Privacy & Security → Accessibility.

## Building

Build and run directly with Swift Package Manager:

```sh
swift build
swift run
```

To produce a proper `.app` bundle (ad-hoc signed):

```sh
scripts/make-app.sh          # outputs ./build/SizeEnforcer.app
scripts/make-app.sh <dir>    # or choose an output directory
```

Then copy `SizeEnforcer.app` to `/Applications` (or launch it in place).

## Usage

1. Launch SizeEnforcer; a `rectangle.dashed` icon appears in the menu bar.
2. Choose **Resize window…** from the menu (or press your configured hotkey).
3. Move the cursor over the target window and click it.
4. Pick one of the registered sizes from the popup, or add a new size.

Open **Settings…** to manage per-app presets, configure the global hotkey, and
toggle whether occluded areas are excluded from the picker highlight.

## License

Released under the [MIT License](LICENSE).
